import Foundation

/// Prevents double submission for the same (schedule entry, condition) pair.
/// Seeded from LocalStore so it survives app relaunches.
final class DuplicateGuard {
    private var attemptedKeys: Set<String>

    init(existingAttempts: [ReservationAttempt]) {
        self.attemptedKeys = Set(existingAttempts.map {
            Self.key(entryID: $0.scheduleEntryID, conditionID: $0.conditionID)
        })
    }

    static func key(entryID: String, conditionID: UUID) -> String {
        "\(entryID)#\(conditionID.uuidString)"
    }

    func hasAttempted(entryID: String, conditionID: UUID) -> Bool {
        attemptedKeys.contains(Self.key(entryID: entryID, conditionID: conditionID))
    }

    func markAttempted(entryID: String, conditionID: UUID) {
        attemptedKeys.insert(Self.key(entryID: entryID, conditionID: conditionID))
    }
}
