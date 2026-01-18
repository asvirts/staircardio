import Combine
import Foundation
import WatchConnectivity
import SwiftUI
import WatchKit

@MainActor
final class WatchSyncManager: NSObject, ObservableObject {
    @Published private(set) var summary: DaySummary?
    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var lastWorkoutSummary: WatchWorkoutSummary?

    private let userDefaults = UserDefaults.standard
    private let pendingKey = "pendingIncrements"
    private let summaryKey = "summaryPayload"

    private let isPreview: Bool

    init(isPreview: Bool = false) {
        self.isPreview = isPreview
        super.init()
        loadCachedSummary()

        guard !isPreview else { return }
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            syncStatus = .syncing
        }
    }

    func incrementOffline() {
        let currentPending = userDefaults.integer(forKey: pendingKey)
        userDefaults.set(currentPending + 1, forKey: pendingKey)

        if var currentSummary = summary {
            currentSummary = DaySummary(
                dayKey: currentSummary.dayKey,
                completed: currentSummary.completed + 1,
                target: currentSummary.target,
                floorsPerCircuit: currentSummary.floorsPerCircuit
            )
            summary = currentSummary
            persistSummary(currentSummary)
        }

        WKInterfaceDevice.current().play(.success)
        flushPendingIfPossible()
    }

    func requestLatestSummary() {
        guard WCSession.default.activationState == .activated else { return }
        syncStatus = .syncing
        WCSession.default.sendMessage(
            [WatchConnectivityKeys.requestSummary: true],
            replyHandler: nil,
            errorHandler: nil
        )
    }

    private func flushPendingIfPossible() {
        guard WCSession.default.activationState == .activated else { return }
        let pending = userDefaults.integer(forKey: pendingKey)
        guard pending > 0 else { return }
        guard let summary else { return }

        let payload: [String: Any] = [
            WatchConnectivityKeys.pendingIncrements: pending,
            DaySummary.dayKeyKey: summary.dayKey
        ]

        syncStatus = .syncing
        WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: { [weak self] _ in
            Task { @MainActor in
                self?.syncStatus = .error
            }
        })
        userDefaults.set(0, forKey: pendingKey)
        WKInterfaceDevice.current().play(.click)
    }

    private func loadCachedSummary() {
        guard let payload = userDefaults.dictionary(forKey: summaryKey) else { return }
        if let summary = DaySummary.from(payload) {
            self.summary = summary
        }
    }

    private func persistSummary(_ summary: DaySummary) {
        userDefaults.set(summary.payload, forKey: summaryKey)
    }

    private func handleSummaryPayload(_ payload: [String: Any]) {
        if let summary = DaySummary.from(payload) {
            self.summary = summary
            persistSummary(summary)
            syncStatus = .synced
            flushPendingIfPossible()
        }

        if let workoutPayload = payload[WatchConnectivityKeys.workoutPayload] as? [String: Any],
           let workoutSummary = WatchWorkoutSummary.from(workoutPayload) {
            lastWorkoutSummary = workoutSummary
        }
    }

    func recordWorkoutSummary(_ summary: WatchWorkoutSummary) {
        lastWorkoutSummary = summary
        syncStatus = .syncing
        sendWorkoutSummary(summary)
        WKInterfaceDevice.current().play(.success)
    }

    private func sendWorkoutSummary(_ summary: WatchWorkoutSummary) {
        guard WCSession.default.activationState == .activated else {
            syncStatus = .error
            return
        }

        guard var payload = self.summary?.payload else {
            syncStatus = .error
            return
        }

        payload[WatchConnectivityKeys.workoutPayload] = summary.payload
        WCSession.default.sendMessage(payload, replyHandler: { [weak self] _ in
            Task { @MainActor in
                self?.syncStatus = .synced
            }
        }, errorHandler: { [weak self] _ in
            Task { @MainActor in
                self?.syncStatus = .error
            }
        })
    }
}

extension WatchSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if activationState == .activated {
                requestLatestSummary()
                flushPendingIfPossible()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            handleSummaryPayload(applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handleSummaryPayload(message)
        }
    }
}
