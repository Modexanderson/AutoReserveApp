import Foundation

/// Local, on-device storage for non-sensitive app state (settings, seen
/// schedule entries, attempt history). Deliberately simple — UserDefaults
/// + JSON — since this is a single-user, single-device app with no sync
/// requirement (development guide, section 3: no cloud sync in scope).
final class LocalStore {
    private let defaults: UserDefaults

    private enum Keys {
        static let cast = "autoreserve.cast"
        static let conditions = "autoreserve.conditions"
        static let seenEntryIDs = "autoreserve.seenEntryIDs"
        static let attempts = "autoreserve.attempts"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadCast() -> Cast? {
        decode(Cast.self, forKey: Keys.cast)
    }

    func saveCast(_ cast: Cast) {
        encode(cast, forKey: Keys.cast)
    }

    func loadConditions() -> [ReservationCondition] {
        decode([ReservationCondition].self, forKey: Keys.conditions) ?? []
    }

    func saveConditions(_ conditions: [ReservationCondition]) {
        encode(conditions, forKey: Keys.conditions)
    }

    func loadSeenEntryIDs() -> [String] {
        defaults.stringArray(forKey: Keys.seenEntryIDs) ?? []
    }

    func saveSeenEntryIDs(_ ids: [String]) {
        defaults.set(ids, forKey: Keys.seenEntryIDs)
    }

    func loadAttempts() -> [ReservationAttempt] {
        decode([ReservationAttempt].self, forKey: Keys.attempts) ?? []
    }

    func saveAttempts(_ attempts: [ReservationAttempt]) {
        encode(attempts, forKey: Keys.attempts)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
