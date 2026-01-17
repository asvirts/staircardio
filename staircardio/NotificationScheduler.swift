import Foundation
import UserNotifications

enum NotificationScheduler {
    static let reminderIdentifierPrefix = "staircardio.reminder"

    static func scheduleReminders(
        startMinutes: Int,
        endMinutes: Int,
        intervalMinutes: Int,
        weekdaysOnly: Bool
    ) {
        cancelAll()

        let clampedInterval = max(intervalMinutes, 15)
        let start = max(startMinutes, 0)
        let end = max(endMinutes, start + 1)

        let calendar = Calendar(identifier: .gregorian)
        let now = Date()

        let fireDates = ReminderScheduleBuilder.buildFireDates(
            calendar: calendar,
            now: now,
            startMinutes: start,
            endMinutes: end,
            intervalMinutes: clampedInterval,
            weekdaysOnly: weekdaysOnly
        )

        let center = UNUserNotificationCenter.current()
        for (index, date) in fireDates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Time for a stair circuit"
            content.body = "Quick climb now keeps the streak alive."
            content.sound = .default
            content.userInfo = ["deepLink": DeepLinkHandler.todayRoute]

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(reminderIdentifierPrefix).\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.add(request)
        }
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: pendingIdentifiers())
    }

    private static func pendingIdentifiers() -> [String] {
        let maxScheduled = 500
        return (0..<maxScheduled).map { "\(reminderIdentifierPrefix).\($0)" }
    }
}
