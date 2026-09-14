import Foundation

@MainActor
final class ResultsViewModel: ObservableObject {
    private let coordinator: ReservationCoordinator

    init(coordinator: ReservationCoordinator) {
        self.coordinator = coordinator
    }

    var attempts: [ReservationAttempt] {
        coordinator.attempts
    }
}
