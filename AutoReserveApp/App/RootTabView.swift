import SwiftUI

struct RootTabView: View {
    @StateObject private var targetVM: TargetSettingsViewModel
    @StateObject private var conditionsVM: ConditionsViewModel
    @StateObject private var contactVM: ContactSettingsViewModel
    @StateObject private var coordinator: ReservationCoordinator
    @StateObject private var monitoringVM: MonitoringViewModel

    init() {
        let store = LocalStore()
        let target = TargetSettingsViewModel(store: store)
        let conditions = ConditionsViewModel(store: store)
        let contact = ContactSettingsViewModel(store: store)

        // Currently wired to the mock providers so the app is always
        // demoable. To run against the REAL site (confirmed real
        // endpoints — see WebViewScheduleProvider.swift and
        // URLSessionBookingProvider.swift for exactly what's been
        // verified vs. what still needs the contact-info field mapping):
        //
        //   let coord = ReservationCoordinator(
        //       scheduleProvider: WebViewScheduleProvider(),
        //       bookingProvider: URLSessionBookingProvider(),
        //       store: store,
        //       notifier: NotificationManager()
        //   )
        let coord = ReservationCoordinator(
            scheduleProvider: MockScheduleProvider(),
            bookingProvider: MockBookingProvider(),
            store: store,
            notifier: NotificationManager()
        )

        _targetVM = StateObject(wrappedValue: target)
        _conditionsVM = StateObject(wrappedValue: conditions)
        _contactVM = StateObject(wrappedValue: contact)
        _coordinator = StateObject(wrappedValue: coord)
        _monitoringVM = StateObject(wrappedValue: MonitoringViewModel(
            coordinator: coord, targetVM: target, conditionsVM: conditions, contactVM: contact
        ))
    }

    var body: some View {
        TabView {
            NavigationStack { TargetSettingsView(viewModel: targetVM) }
                .tabItem { Label("Target", systemImage: "person.crop.circle") }

            NavigationStack { ConditionsSettingsView(viewModel: conditionsVM) }
                .tabItem { Label("Conditions", systemImage: "slider.horizontal.3") }

            NavigationStack { ContactSettingsView(viewModel: contactVM) }
                .tabItem { Label("Contact", systemImage: "person.text.rectangle") }

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
