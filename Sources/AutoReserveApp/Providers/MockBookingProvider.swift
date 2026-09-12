import Foundation

final class MockBookingProvider: BookingProviding {
    /// Flip to false to exercise the failure path in the demo/UI.
    var simulateSuccess: Bool = true

    func book(entry: ScheduleEntry, for cast: Cast) async throws -> String {
        try await Task.sleep(nanoseconds: 500_000_000)
        if simulateSuccess {
            return "Mock booking confirmed for \(entry.date.formatted(date: .abbreviated, time: .omitted)) \(entry.startTime)."
        } else {
            throw AppError.bookingUnconfirmed("Mock provider configured to simulate failure.")
        }
    }
}
