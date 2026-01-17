import Combine
import Foundation
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    @Published var remindersEnabled: Bool {
        didSet {
            userDefaults.set(remindersEnabled, forKey: remindersEnabledKey)
        }
    }

    @Published var startMinutes: Int {
        didSet {
            userDefaults.set(startMinutes, forKey: startMinutesKey)
        }
    }

    @Published var endMinutes: Int {
        didSet {
            userDefaults.set(endMinutes, forKey: endMinutesKey)
        }
    }

    @Published var intervalMinutes: Int {
        didSet {
            userDefaults.set(intervalMinutes, forKey: intervalMinutesKey)
        }
    }

    @Published var floorsPerCircuit: Int {
        didSet {
            if floorsPerCircuit < 1 {
                floorsPerCircuit = 1
            }
            userDefaults.set(floorsPerCircuit, forKey: floorsPerCircuitKey)
        }
    }

    @Published var notificationStatusMessage: String?

    let weekdaysOnly = true

    private let userDefaults: UserDefaults
    private let remindersEnabledKey = "remindersEnabled"
    private let startMinutesKey = "reminderStartMinutes"
    private let endMinutesKey = "reminderEndMinutes"
    private let intervalMinutesKey = "reminderIntervalMinutes"
    private let floorsPerCircuitKey = "floorsPerCircuit"
    private let hasRequestedHealthKitKey = "hasRequestedHealthKit"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let storedEnabled = userDefaults.object(forKey: remindersEnabledKey) as? Bool
        let storedStart = userDefaults.object(forKey: startMinutesKey) as? Int
        let storedEnd = userDefaults.object(forKey: endMinutesKey) as? Int
        let storedInterval = userDefaults.object(forKey: intervalMinutesKey) as? Int

        remindersEnabled = storedEnabled ?? false
        startMinutes = storedStart ?? 9 * 60
        endMinutes = storedEnd ?? 17 * 60
        let intervalValue = storedInterval ?? 90
        intervalMinutes = NotificationIntervalOption.closest(to: intervalValue).minutes

        let storedFloors = userDefaults.object(forKey: floorsPerCircuitKey) as? Int
        floorsPerCircuit = max(storedFloors ?? 4, 1)
    }

    var shouldRequestHealthKitAuthorization: Bool {
        !userDefaults.bool(forKey: hasRequestedHealthKitKey)
    }

    func markHealthKitAuthorizationRequested() {
        userDefaults.set(true, forKey: hasRequestedHealthKitKey)
    }

    func handleRemindersToggleChanged(enabled: Bool, goalReached: Bool) async {
        if enabled {
            let granted = await requestAuthorizationIfNeeded()
            if !granted {
                remindersEnabled = false
                notificationStatusMessage = "Notifications are disabled in Settings."
                NotificationScheduler.cancelAll()
                return
            }
        }

        notificationStatusMessage = nil
        scheduleOrCancelReminders(goalReached: goalReached)
    }

    func scheduleOrCancelReminders(goalReached: Bool) {
        guard remindersEnabled, !goalReached else {
            notificationStatusMessage = nil
            NotificationScheduler.cancelAll()
            return
        }

        guard startMinutes < endMinutes else {
            notificationStatusMessage = "Start time must be before end time."
            NotificationScheduler.cancelAll()
            return
        }

        notificationStatusMessage = nil
        NotificationScheduler.scheduleReminders(
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            intervalMinutes: intervalMinutes,
            weekdaysOnly: weekdaysOnly
        )
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await notificationSettings(center: center)

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return await requestAuthorization(center: center)
        @unknown default:
            return false
        }
    }

    private func notificationSettings(center: UNUserNotificationCenter) async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func requestAuthorization(center: UNUserNotificationCenter) async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}
