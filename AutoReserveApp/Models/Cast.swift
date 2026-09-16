import Foundation

/// Represents the specific person/listing being monitored.
struct Cast: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var shopName: String
    var shopURL: URL?
    var castPageURL: URL?
    /// The site's internal numeric ID for this girl (visible in the real
    /// calendar/booking URLs, e.g. "55983930" for the cast used during
    /// testing). Required for WebViewScheduleProvider/WebViewBookingProvider.
    var girlID: String = ""
    var notes: String?
}
