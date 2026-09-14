import Foundation
import BackgroundTasks

/// Best-effort background refresh only. iOS decides if and when this
/// actually runs — this can NOT be relied on for anything time-sensitive.
/// See development guide, section 4, and Apple's "Using Background Tasks
/// to Update Your App".
final class BackgroundCoordinator {
    static let taskIdentifier = "com.autoreserve.refresh"

    private let onRefresh: () async -> Void

    init(onRefresh: @escaping () async -> Void) {
        self.onRefresh = onRefresh
    }

    /// Call once at app launch (before `application(_:didFinishLaunchingWithOptions:)`
    /// returns, or in the SwiftUI App's init).
    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            self.handle(task: refreshTask)
        }
    }

    /// Call after each successful run, and whenever the app goes to the
    /// background, to ask iOS for another chance later. This is a hint,
    /// not a guarantee — iOS may run it earlier, later, or not at all.
    func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handle(task: BGAppRefreshTask) {
        scheduleNext()

        let workItem = Task {
            await onRefresh()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            workItem.cancel()
        }
    }
}
