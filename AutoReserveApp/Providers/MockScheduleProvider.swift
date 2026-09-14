import Foundation

/// Deterministic fake data so the whole app is runnable and demoable today,
/// without needing real credentials or a real target site.
final class MockScheduleProvider: ScheduleProviding {
    func fetchSchedule(for cast: Cast) async throws -> [ScheduleEntry] {
        try await Task.sleep(nanoseconds: 300_000_000)
        let calendar = Calendar.current
        let today = Date()
        return (1...3).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            return ScheduleEntry(
                id: "mock-\(offset)-\(calendar.component(.day, from: date))",
                date: date,
                startTime: offset % 2 == 0 ? "13:00" : "19:00",
                endTime: nil,
                course: "60min",
                rawLabel: "Mock slot #\(offset)"
            )
        }
    }
}
