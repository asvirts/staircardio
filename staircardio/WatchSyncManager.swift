import Combine
import Foundation
import SwiftData
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
final class WatchSyncManager: NSObject, ObservableObject {
    @Published private(set) var lastSummary: DaySummary?

    private var modelContainer: ModelContainer?
    private let remindersModel = AppModel()
    private let dateFormatter: DateFormatter
    private var todayKey: String {
        dateFormatter.string(from: Date())
    }
    private let isPreview: Bool

    init(isPreview: Bool = false) {
        self.isPreview = isPreview
        self.dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        super.init()

        guard !isPreview else { return }
        #if canImport(WatchConnectivity)
        activateSession()
        #endif
    }

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        refreshSummary()
    }

    func refreshSummary() {
        guard let context = modelContainer?.mainContext else { return }
        let log = fetchTodayLog(using: context)
        lastSummary = DaySummary(dayKey: log.dayKey, completed: log.completed, target: log.target)
        sendSummary()
        remindersModel.scheduleOrCancelReminders(goalReached: log.completed >= log.target)
    }

    func applyIncrement(count: Int) {
        guard count > 0 else { return }
        guard let context = modelContainer?.mainContext else { return }
        let log = fetchTodayLog(using: context)
        log.completed += count
        do {
            try context.save()
        } catch {
            print("Failed to save watch increment: \(error)")
        }
        refreshSummary()
    }

    private func activateSession() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        #endif
    }

    private func sendSummary() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        guard let summary = lastSummary else { return }

        do {
            try session.updateApplicationContext(summary.payload)
        } catch {
            print("Failed to update watch context: \(error)")
        }
        #endif
    }

    private func fetchTodayLog(using context: ModelContext) -> DayLog {
        let key = dateFormatter.string(from: Date())
        let descriptor = FetchDescriptor<DayLog>(
            predicate: #Predicate { $0.dayKey == key }
        )

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let created = DayLog(dayKey: key)
        context.insert(created)
        return created
    }

    private func handleMessage(_ message: [String: Any]) {
        if message[WatchConnectivityKeys.requestSummary] as? Bool == true {
            refreshSummary()
            return
        }

        if let count = message[WatchConnectivityKeys.pendingIncrements] as? Int {
            let requestedDayKey = message[DaySummary.dayKeyKey] as? String
            if let requestedDayKey, requestedDayKey != todayKey {
                refreshSummary()
                return
            }
            applyIncrement(count: count)
            return
        }

    }
}

#if canImport(WatchConnectivity)
extension WatchSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if activationState == .activated {
                refreshSummary()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handleMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let summary = DaySummary.from(applicationContext) {
                lastSummary = summary
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
#endif
