import Foundation

/// Real, observed states for a single time slot on the live calendar
/// (confirmed via HAR capture against yoyaku.cityheaven.net, Sept 2026):
///   - available:    circle_icon.png  — directly bookable
///   - phoneOnly:    tel_icon.png     — site requires a phone call, not automatable
///   - unavailable:  x_icon.png / blank — nothing to do
///   - waitlist:     bell_icon.png    — no open slot, but a cancellation-waitlist
///                    request can be submitted (separate flow/endpoint from booking)
enum SlotStatus: String, Codable {
    case available
    case phoneOnly
    case unavailable
    case waitlist
}

/// A single work-schedule slot as read from the target site.
struct ScheduleEntry: Identifiable, Codable, Equatable, Hashable {
    /// Stable identity used to diff against previously-seen entries.
    /// Built as "{date}-{time}" since that's what's actually stable on this
    /// site (there's no separate shift/slot ID in the markup).
    var id: String
    var date: Date
    var startTime: String
    var status: SlotStatus
    var course: String? = nil
    var discoveredAt: Date = Date()
}
