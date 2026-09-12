import SwiftUI

struct ResultsView: View {
    @ObservedObject var coordinator: ReservationCoordinator

    var body: some View {
        List(coordinator.attempts) { attempt in
            VStack(alignment: .leading) {
                Text(attempt.outcome.rawValue.capitalized)
                    .font(.headline)
                if let message = attempt.message {
                    Text(message).font(.caption)
                }
                Text(attempt.attemptedAt.formatted(date: .abbreviated, time: .standard))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Results")
    }
}
