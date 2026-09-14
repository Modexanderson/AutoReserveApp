import Foundation

/// Represents the specific person/listing being monitored.
struct Cast: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var shopName: String
    var shopURL: URL?
    var castPageURL: URL?
    var notes: String?
}
