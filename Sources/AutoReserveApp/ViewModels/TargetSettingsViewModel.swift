import Foundation

@MainActor
final class TargetSettingsViewModel: ObservableObject {
    @Published var cast: Cast
    private let store: LocalStore

    init(store: LocalStore) {
        self.store = store
        self.cast = store.loadCast() ?? Cast(name: "", shopName: "", shopURL: nil, castPageURL: nil, notes: nil)
    }

    func save() {
        store.saveCast(cast)
    }
}
