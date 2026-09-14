import XCTest
@testable import AutoReserveApp

final class ConditionMatcherTests: XCTestCase {
    func testMatchesWithinTimeRange() {
        var condition = ReservationCondition(priority: .first)
        condition.earliestTime = "12:00"
        condition.latestTime = "18:00"

        let entry = ScheduleEntry(id: "1", date: Date(), startTime: "14:00")
        let matcher = ConditionMatcher()

        XCTAssertNotNil(matcher.firstMatch(for: entry, in: [condition]))
    }

    func testNoMatchOutsideTimeRange() {
        var condition = ReservationCondition(priority: .first)
        condition.earliestTime = "12:00"
        condition.latestTime = "13:00"

        let entry = ScheduleEntry(id: "1", date: Date(), startTime: "20:00")
        let matcher = ConditionMatcher()

        XCTAssertNil(matcher.firstMatch(for: entry, in: [condition]))
    }

    func testPriorityOrderRespected() {
        var first = ReservationCondition(priority: .first)
        first.course = "90min"
        var second = ReservationCondition(priority: .second)
        second.course = "60min"

        let entry = ScheduleEntry(id: "1", date: Date(), startTime: "14:00", course: "60min")
        let matcher = ConditionMatcher()

        let result = matcher.firstMatch(for: entry, in: [first, second])
        XCTAssertEqual(result?.priority, .second)
    }
}
