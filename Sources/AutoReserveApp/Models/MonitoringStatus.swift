import Foundation

enum AuthState: String, Codable {
    case unknown
    case loggedIn
    case loggedOut
    case expired
}

enum MonitoringState: String, Codable {
    case idle
    case running
    case error
}

struct MonitoringStatus: Codable, Equatable {
    var state: MonitoringState = .idle
    var lastCheckedAt: Date?
    var lastError: String?
    var authState: AuthState = .unknown
}
