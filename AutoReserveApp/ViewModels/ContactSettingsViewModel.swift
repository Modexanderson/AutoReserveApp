import Foundation

@MainActor
final class ContactSettingsViewModel: ObservableObject {
    @Published var contact: ContactInfo
    private let store: LocalStore

    init(store: LocalStore) {
        self.store = store
        self.contact = store.loadContact()
    }

    func save() {
        store.saveContact(contact)
    }
}
