import Foundation

/// Abstracts "how do we get the current schedule". This is the seam the
/// real, site-specific implementation plugs into once Phase 0 research
/// (development guide, section 6) has confirmed the target page's structure.
protocol ScheduleProviding {
    func fetchSchedule(for cast: Cast) async throws -> [ScheduleEntry]
}
