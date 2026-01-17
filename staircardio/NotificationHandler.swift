import Foundation
import UIKit
import UserNotifications

final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if DeepLinkHandler.shouldOpenToday(from: response.notification.request.content.userInfo) {
            openDeepLink()
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private func openDeepLink() {
        guard let url = URL(string: DeepLinkHandler.todayRoute) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
}
