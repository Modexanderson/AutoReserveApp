import Foundation

/// Orchestrates the end-to-end flow from the development guide (sections
/// 1.1 and 8): detect new schedule -> match conditions in priority order ->
/// attempt booking -> verify success -> record result -> never double-book.
@MainActor
final class ReservationCoordinator: ObservableObject {
    @Published var status = MonitoringStatus()
    @Published private(set) var attempts: [ReservationAttempt] = []

    private let scheduleProvider: ScheduleProviding
    private let bookingProvider: BookingProviding
    private let matcher = ConditionMatcher()
    private var duplicateGuard: DuplicateGuard
    private let store: LocalStore
    private let notifier: NotificationManaging

    private var seenEntryIDs: Set<String>

    init(
        scheduleProvider: ScheduleProviding,
        bookingProvider: BookingProviding,
        store: LocalStore,
        notifier: NotificationManaging
    ) {
        self.scheduleProvider = scheduleProvider
        self.bookingProvider = bookingProvider
        self.store = store
        self.notifier = notifier
        let loadedAttempts = store.loadAttempts()
        self.attempts = loadedAttempts
        self.duplicateGuard = DuplicateGuard(existingAttempts: loadedAttempts)
        self.seenEntryIDs = Set(store.loadSeenEntryIDs())
    }

    /// Runs a single check cycle. Safe to call repeatedly — from a
    /// foreground timer, or from a background refresh task if/when iOS
    /// actually grants one (see BackgroundCoordinator for why that can't
    /// be guaranteed to happen on any particular schedule).
    func runCheckCycle(cast: Cast, conditions: [ReservationCondition]) async {
        status.state = .running
        do {
            let entries = try await scheduleProvider.fetchSchedule(for: cast)
            status.lastCheckedAt = Date()
            status.lastError = nil

            let newEntries = entries.filter { !seenEntryIDs.contains($0.id) }
            for entry in newEntries {
                seenEntryIDs.insert(entry.id)
                await handle(newEntry: entry, cast: cast, conditions: conditions)
            }
            store.saveSeenEntryIDs(Array(seenEntryIDs))
            status.state = .idle
        } catch AppError.sessionExpired {
            status.authState = .expired
            status.state = .error
            status.lastError = AppError.sessionExpired.localizedDescription
            notifier.notify(title: "Login required", body: "Your session expired — please re-login in the app.")
        } catch {
            status.state = .error
            status.lastError = error.localizedDescription
        }
    }

    private func handle(newEntry entry: ScheduleEntry, cast: Cast, conditions: [ReservationCondition]) async {
        guard let condition = matcher.firstMatch(for: entry, in: conditions) else {
            recordAttempt(entry: entry, conditionID: nil, priority: nil, outcome: .skippedNoMatch, message: "No condition matched this slot.")
            return
        }

        if duplicateGuard.hasAttempted(entryID: entry.id, conditionID: condition.id) {
            recordAttempt(entry: entry, conditionID: condition.id, priority: condition.priority, outcome: .skippedDuplicate, message: "Already attempted.")
            return
        }

        duplicateGuard.markAttempted(entryID: entry.id, conditionID: condition.id)

        do {
            let confirmation = try await bookingProvider.book(entry: entry, for: cast)
            // Only ever treated as success once the provider itself has
            // verified a real confirmation — never on transport success
            // alone (development guide, sections 8 & 10).
            recordAttempt(entry: entry, conditionID: condition.id, priority: condition.priority, outcome: .succeeded, message: confirmation)
            notifier.notify(title: "Booking confirmed", body: "\(cast.name) — \(entry.date.formatted(date: .abbreviated, time: .omitted)) \(entry.startTime)")
        } catch {
            recordAttempt(entry: entry, conditionID: condition.id, priority: condition.priority, outcome: .failed, message: error.localizedDescription)
            notifier.notify(title: "Booking failed", body: error.localizedDescription)
        }
    }

    private func recordAttempt(entry: ScheduleEntry, conditionID: UUID?, priority: ConditionPriority?, outcome: ReservationOutcome, message: String?) {
        // conditionID/priority are nil only for the "no condition matched"
        // case, where there's nothing meaningful to attribute the skip to.
        let attempt = ReservationAttempt(
            scheduleEntryID: entry.id,
            conditionID: conditionID ?? UUID(),
            priority: priority ?? .third,
            outcome: outcome,
            message: message
        )
        attempts.insert(attempt, at: 0)
        store.saveAttempts(attempts)
    }
}
