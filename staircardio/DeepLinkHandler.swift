import Foundation

enum DeepLinkHandler {
    static let todayRoute = "staircardio://today"

    static func shouldOpenToday(from userInfo: [AnyHashable: Any]) -> Bool {
        guard let deepLink = userInfo["deepLink"] as? String else { return false }
        return deepLink == todayRoute
    }
}
