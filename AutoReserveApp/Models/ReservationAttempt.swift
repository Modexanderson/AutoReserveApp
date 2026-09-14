import Foundation

enum ReservationOutcome: String, Codable {
    case pending
    case succeeded
    case failed
    case skippedDuplicate
    case skippedNoMatch
}

struct ReservationAttempt: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var scheduleEntryID: String
    var conditionID: UUID
    var priority: ConditionPriority
    var outcome: ReservationOutcome
    var message: String?
    var attemptedAt: Date = Date()
}
