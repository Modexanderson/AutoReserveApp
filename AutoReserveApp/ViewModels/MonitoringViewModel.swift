import Foundation

@MainActor
final class MonitoringViewModel: ObservableObject {
    @Published var isMonitoring = false
    /// Foreground polling interval. This is the ONLY interval that's
    /// actually reliable — background refresh is best-effort (see
    /// BackgroundCoordinator).
    @Published var intervalSeconds: TimeInterval = 60

    private var timerTask: Task<Void, Never>?
    let coordinator: ReservationCoordinator
    private let targetVM: TargetSettingsViewModel
    private let conditionsVM: ConditionsViewModel

    init(coordinator: ReservationCoordinator, targetVM: TargetSettingsViewModel, conditionsVM: ConditionsViewModel) {
        self.coordinator = coordinator
        self.targetVM = targetVM
        self.conditionsVM = conditionsVM
    }

    func start() {
        guard !isMonitoring else { return }
        isMonitoring = true
        timerTask = Task {
            while !Task.isCancelled && isMonitoring {
                await coordinator.runCheckCycle(cast: targetVM.cast, conditions: conditionsVM.conditions)
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }
    }

    func stop() {
        isMonitoring = false
        timerTask?.cancel()
        timerTask = nil
    }
}
