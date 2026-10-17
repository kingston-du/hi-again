import Foundation

enum ScanOutcome { case met(Profile, meetingId: UUID, timesMet: Int), unknown, ownCard }

enum ClaimResult: String { case linked, alreadyYours = "already_yours", taken }

struct Place { let name: String?; let lat: Double; let lng: Double }
