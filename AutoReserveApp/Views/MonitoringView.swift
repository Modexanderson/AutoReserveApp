import SwiftUI

struct MonitoringView: View {
    @ObservedObject var viewModel: MonitoringViewModel
    @ObservedObject var coordinator: ReservationCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text(coordinator.status.state.rawValue.capitalized)
                .font(.title2)

            if let last = coordinator.status.lastCheckedAt {
                Text("Last checked: \(last.formatted(date: .abbreviated, time: .standard))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = coordinator.status.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button(viewModel.isMonitoring ? "Stop Monitoring" : "Start Monitoring") {
                viewModel.isMonitoring ? viewModel.stop() : viewModel.start()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Monitoring")
    }
}
