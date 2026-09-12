import Foundation

/// Distinguishes failure classes so the app never silently guesses at
/// success and never retries indefinitely (development guide, sections 8 & 10).
enum AppError: Error, LocalizedError {
    case network(String)
    case sessionExpired
    case parsingFailed(String)
    case duplicateAttempt
    case bookingUnconfirmed(String)
    case siteStructureChanged(String)

    var errorDescription: String? {
        switch self {
        case .network(let msg): return "Network error: \(msg)"
        case .sessionExpired: return "Session expired — please log in again."
        case .parsingFailed(let msg): return "Could not parse page content: \(msg)"
        case .duplicateAttempt: return "This slot was already attempted."
        case .bookingUnconfirmed(let msg): return "Booking could not be confirmed: \(msg)"
        case .siteStructureChanged(let msg): return "Site structure appears to have changed: \(msg)"
        }
    }
}
