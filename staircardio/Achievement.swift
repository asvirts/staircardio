import Foundation
import SwiftData

enum BadgeType: String, Codable {
    case streak = "streak"
    case totalCircuits = "totalCircuits"
    case consistency = "consistency"
    case healthImprovement = "healthImprovement"
}

@Model
final class Achievement {
    var id: UUID = UUID()
    var title: String = ""
    var badgeDescription: String = ""
    var badgeTypeRaw: String = BadgeType.streak.rawValue
    var earnedDate: Date = Date()
    var icon: String = ""
    var threshold: Int = 0
    var isEarned: Bool = false

    init(
        id: UUID = UUID(),
        title: String,
        badgeDescription: String,
        badgeType: BadgeType,
        earnedDate: Date,
        icon: String,
        threshold: Int,
        isEarned: Bool
    ) {
        self.id = id
        self.title = title
        self.badgeDescription = badgeDescription
        self.badgeTypeRaw = badgeType.rawValue
        self.earnedDate = earnedDate
        self.icon = icon
        self.threshold = threshold
        self.isEarned = isEarned
    }

    var badgeType: BadgeType {
        get {
            BadgeType(rawValue: badgeTypeRaw) ?? .streak
        }
        set {
            badgeTypeRaw = newValue.rawValue
        }
    }
}
