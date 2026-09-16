import Foundation

enum ConditionPriority: Int, Codable, CaseIterable, Comparable {
    case first = 1
    case second = 2
    case third = 3

    static func < (lhs: ConditionPriority, rhs: ConditionPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .first: return "1st choice"
        case .second: return "2nd choice"
        case .third: return "3rd choice"
        }
    }
}

/// A single preferred booking condition (one of the 1st-3rd choices).
///
/// NOTE: the real-world meaning of "1st-3rd choice" (fixed date/time vs. a
/// time range vs. a day-of-week rule, etc.) is still an open question per
/// the client's development guide (section 8). This model covers the
/// common cases; extend `matches(_:)` once the real definition is confirmed
/// with the client.
struct ReservationCondition: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var priority: ConditionPriority
    var dayOfWeek: Int?        // 1 = Sunday ... 7 = Saturday, optional
    var exactDate: Date?       // optional fixed date
    var earliestTime: String?  // "HH:mm", optional lower bound
    var latestTime: String?    // "HH:mm", optional upper bound
    var course: String?
    var isEnabled: Bool = true

    /// True if `entry` satisfies this condition. Conservative by design:
    /// an unset field means "don't care", but every field that IS set
    /// must match.
    func matches(_ entry: ScheduleEntry, calendar: Calendar = .current) -> Bool {
        guard isEnabled else { return false }

        if let exactDate, !calendar.isDate(exactDate, inSameDayAs: entry.date) {
            return false
        }

        if let dayOfWeek {
            let weekday = calendar.component(.weekday, from: entry.date)
            if weekday != dayOfWeek { return false }
        }

        if let earliestTime, entry.startTime < earliestTime { return false }
        if let latestTime, entry.startTime > latestTime { return false }

        // NOTE: the real calendar page carries no per-slot course info —
        // only availability status (see SlotStatus). Course matching here
        // only fires against mock/test data that sets `course` on the
        // entry; against the real site, the desired course is applied
        // later at the booking step (URLSessionBookingProvider reads it
        // from THIS condition, not from the entry). So a course
        // preference here doesn't gate which real slots get attempted —
        // it just determines which course gets selected once one does.
        if let course, let entryCourse = entry.course, course != entryCourse {
            return false
        }

        return true
    }
}
