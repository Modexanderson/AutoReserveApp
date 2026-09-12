import Foundation

/// Evaluates a new schedule entry against the user's ranked conditions and
/// returns the highest-priority (1st before 2nd before 3rd) match, if any.
struct ConditionMatcher {
    func firstMatch(for entry: ScheduleEntry, in conditions: [ReservationCondition]) -> ReservationCondition? {
        conditions
            .filter { $0.isEnabled }
            .sorted { $0.priority < $1.priority }
            .first { $0.matches(entry) }
    }
}
