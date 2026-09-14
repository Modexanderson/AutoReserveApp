import XCTest
@testable import AutoReserveApp

final class DuplicateGuardTests: XCTestCase {
    func testDetectsDuplicateAfterMarking() {
        let dupGuard = DuplicateGuard(existingAttempts: [])
        let conditionID = UUID()

        XCTAssertFalse(dupGuard.hasAttempted(entryID: "e1", conditionID: conditionID))
        dupGuard.markAttempted(entryID: "e1", conditionID: conditionID)
        XCTAssertTrue(dupGuard.hasAttempted(entryID: "e1", conditionID: conditionID))
    }

    func testSeededFromExistingAttempts() {
        let existing = [ReservationAttempt(scheduleEntryID: "e1", conditionID: UUID(), priority: .first, outcome: .succeeded)]
        let dupGuard = DuplicateGuard(existingAttempts: existing)
        XCTAssertTrue(dupGuard.hasAttempted(entryID: existing[0].scheduleEntryID, conditionID: existing[0].conditionID))
    }
}
