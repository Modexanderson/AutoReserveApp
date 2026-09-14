import Foundation

/// A single work-schedule slot as published on the target site.
struct ScheduleEntry: Identifiable, Codable, Equatable, Hashable {
    /// Stable identity used to diff against previously-seen entries.
    /// Should be derived from something the site won't change arbitrarily
    /// (e.g. a shift id embedded in the page, or date+time+course).
    var id: String
    var date: Date
    var startTime: String
    var endTime: String?
    var course: String?
    var rawLabel: String?
    var discoveredAt: Date = Date()
}
