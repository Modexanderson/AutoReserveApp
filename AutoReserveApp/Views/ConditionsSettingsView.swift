import SwiftUI

struct ConditionsSettingsView: View {
    @ObservedObject var viewModel: ConditionsViewModel

    var body: some View {
        Form {
            ForEach($viewModel.conditions) { $condition in
                Section(condition.priority.label) {
                    Toggle("Enabled", isOn: $condition.isEnabled)
                    TextField("Earliest time (HH:mm)", text: Binding(
                        get: { condition.earliestTime ?? "" },
                        set: { condition.earliestTime = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Latest time (HH:mm)", text: Binding(
                        get: { condition.latestTime ?? "" },
                        set: { condition.latestTime = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Course", text: Binding(
                        get: { condition.course ?? "" },
                        set: { condition.course = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
        }
        .navigationTitle("Preferred Conditions")
        .toolbar {
            Button("Save") { viewModel.save() }
        }
    }
}
