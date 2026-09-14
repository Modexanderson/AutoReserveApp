import Foundation

/// Abstracts "how do we actually submit and verify a booking". Real
/// implementations must only report success once a genuine confirmation
/// has been observed (development guide, section 8) — never on transport
/// success alone.
protocol BookingProviding {
    /// Returns a human-readable confirmation string on verified success,
    /// or throws on anything else — including "we couldn't tell".
    func book(entry: ScheduleEntry, for cast: Cast) async throws -> String
}
