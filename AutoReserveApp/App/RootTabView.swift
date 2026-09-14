import SwiftUI

struct RootTabView: View {
    @StateObject private var targetVM: TargetSettingsViewModel
    @StateObject private var conditionsVM: ConditionsViewModel
    @StateObject private var coordinator: ReservationCoordinator
    @StateObject private var monitoringVM: MonitoringViewModel

    init() {
        let store = LocalStore()
        let target = TargetSettingsViewModel(store: store)
        let conditions = ConditionsViewModel(store: store)

        // Wired to the mock providers today. Swap these two lines for
        // HTMLScheduleProvider / HTMLBookingProvider once Phase 0 research
        // is complete and those two files have real implementations.
        let coord = ReservationCoordinator(
            scheduleProvider: MockScheduleProvider(),
            bookingProvider: MockBookingProvider(),
            store: store,
            notifier: NotificationManager()
        )

        _targetVM = StateObject(wrappedValue: target)
        _conditionsVM = StateObject(wrappedValue: conditions)
        _coordinator = StateObject(wrappedValue: coord)
        _monitoringVM = StateObject(wrappedValue: MonitoringViewModel(coordinator: coord, targetVM: target, conditionsVM: conditions))
    }

    var body: some View {
        TabView {
            NavigationStack { TargetSettingsView(viewModel: targetVM) }
                .tabItem { Label("Target", systemImage: "person.crop.circle") }

            NavigationStack { ConditionsSettingsView(viewModel: conditionsVM) }
                .tabItem { Label("Conditions", systemImage: "slider.horizontal.3") }

            NavigationStack { MonitoringView(viewModel: monitoringVM, coordinator: coordinator) }
                .tabItem { Label("Monitor", systemImage: "eye") }

            NavigationStack { ResultsView(coordinator: coordinator) }
                .tabItem { Label("Results", systemImage: "checklist") }
        }
        .onAppear {
            NotificationManager().requestAuthorizationIfNeeded()
        }
    }
}
