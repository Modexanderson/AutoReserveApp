import Foundation

@MainActor
final class ConditionsViewModel: ObservableObject {
    @Published var conditions: [ReservationCondition]
    private let store: LocalStore

    init(store: LocalStore) {
        self.store = store
        let loaded = store.loadConditions()
        self.conditions = loaded.isEmpty ? Self.defaultConditions() : loaded
    }

    static func defaultConditions() -> [ReservationCondition] {
        ConditionPriority.allCases.map { ReservationCondition(priority: $0) }
    }

    func save() {
        store.saveConditions(conditions)
    }
}
