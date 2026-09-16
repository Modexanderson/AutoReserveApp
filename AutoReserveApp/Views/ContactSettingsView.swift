import SwiftUI

/// The real site's guest-checkout form requires a name and phone number
/// per booking (confirmed from the flow: 連絡先入力 = "enter contact info").
/// Note from the shop's own booking rules: nicknames aren't accepted —
/// use a real-looking Japanese name for the "name" field.
struct ContactSettingsView: View {
    @ObservedObject var viewModel: ContactSettingsViewModel

    var body: some View {
        Form {
            Section("Contact Info (used to fill the site's booking form)") {
                TextField("Name", text: $viewModel.contact.name)
                TextField("Phone number", text: $viewModel.contact.phoneNumber)
                    .keyboardType(.phonePad)
            }
        }
        .navigationTitle("Contact")
        .toolbar {
            Button("Save") { viewModel.save() }
        }
    }
}
