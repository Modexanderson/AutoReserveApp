import Foundation

/// Abstracts "how do we actually submit and verify a booking or a
/// cancellation-waitlist request". Real implementations must only report
/// success once a genuine confirmation has been observed (development
/// guide, section 8) — never on transport success alone.
protocol BookingProviding {
    /// Returns a human-readable confirmation string on verified success,
    /// or throws on anything else — including "we couldn't tell".
    /// The action taken (direct booking vs. waitlist request) is derived
    /// from `entry.status` — see `ScheduleEntry.SlotStatus`. `condition`
    /// is passed so the provider knows the desired course (the calendar
    /// page itself carries no per-slot course info — only availability).
    func book(entry: ScheduleEntry, condition: ReservationCondition, for cast: Cast, contact: ContactInfo) async throws -> String
}

struct ContactInfo: Codable, Equatable {
    var name: String = ""
    var phoneNumber: String = ""
}
