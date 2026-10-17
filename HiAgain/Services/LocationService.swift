import Foundation
import CoreLocation

/// One fix plus reverse geocode, giving up after 2 seconds. A scan never waits on location.
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var fixContinuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    @MainActor
    func currentPlace() async throws -> Place? {
        let deadline = Date().addingTimeInterval(2)
        guard let location = await withTimeout(seconds: 2, fallback: nil, operation: { await self.fix() }) else {
            return nil
        }
        let remaining = max(0.1, deadline.timeIntervalSinceNow)
        let name = await withTimeout(seconds: remaining, fallback: nil) { await Self.placeName(for: location) }
        return Place(name: name, lat: location.coordinate.latitude, lng: location.coordinate.longitude)
    }

    /// Asks permission once if needed, then returns the first location (or nil if denied).
    @MainActor
    private func fix() async -> CLLocation? {
        switch manager.authorizationStatus {
        case .denied, .restricted: return nil
        default: break
        }
        if let recent = manager.location, recent.timestamp.timeIntervalSinceNow > -60 { return recent }
        fixContinuation?.resume(returning: nil)
        return await withCheckedContinuation { continuation in
            fixContinuation = continuation
            if manager.authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    /// Prefers a point-of-interest name ("HUB"), then the street or neighborhood.
    private static func placeName(for location: CLLocation) async -> String? {
        guard let mark = try? await CLGeocoder().reverseGeocodeLocation(location).first else { return nil }
        return mark.areasOfInterest?.first ?? mark.name ?? mark.subLocality ?? mark.locality
    }

    private func resumeFix(_ location: CLLocation?) {
        fixContinuation?.resume(returning: location)
        fixContinuation = nil
    }

    // MARK: CLLocationManagerDelegate (main thread, since the manager was made there)

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard fixContinuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        case .denied, .restricted: resumeFix(nil)
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        resumeFix(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resumeFix(nil)
    }
}

/// Returns the operation's result, or `fallback` if it takes longer than `seconds`.
func withTimeout<T: Sendable>(seconds: TimeInterval, fallback: T, operation: @escaping @Sendable () async -> T) async -> T {
    await withTaskGroup(of: T.self) { group in
        group.addTask { await operation() }
        group.addTask {
            try? await Task.sleep(for: .seconds(seconds))
            return fallback
        }
        let first = await group.next() ?? fallback
        group.cancelAll()
        return first
    }
}
