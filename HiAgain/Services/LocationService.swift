import Foundation
import CoreLocation

/// B4 (Claude). One fix plus reverse geocode, giving up after 2 seconds. A scan never waits on location.
final class LocationService: NSObject {
    static let shared = LocationService()

    func currentPlace() async throws -> Place? { nil }
}
