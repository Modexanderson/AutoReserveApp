import SwiftUI

struct TargetSettingsView: View {
    @ObservedObject var viewModel: TargetSettingsViewModel

    var body: some View {
        Form {
            Section("Shop") {
                TextField("Shop name", text: $viewModel.cast.shopName)
                TextField("Shop URL", text: Binding(
                    get: { viewModel.cast.shopURL?.absoluteString ?? "" },
                    set: { viewModel.cast.shopURL = URL(string: $0) }
                ))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
            }
            Section("Cast") {
                TextField("Cast name", text: $viewModel.cast.name)
                TextField("Cast page URL", text: Binding(
                    get: { viewModel.cast.castPageURL?.absoluteString ?? "" },
                    set: { viewModel.cast.castPageURL = URL(string: $0) }
                ))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
            }
            Section("Notes") {
                TextField("Notes", text: Binding(
                    get: { viewModel.cast.notes ?? "" },
                    set: { viewModel.cast.notes = $0 }
                ))
            }
        }
        .navigationTitle("Target")
        .toolbar {
            Button("Save") { viewModel.save() }
        }
    }
}
