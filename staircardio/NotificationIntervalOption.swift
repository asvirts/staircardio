import Foundation

enum NotificationIntervalOption: CaseIterable {
    case thirty
    case fortyFive
    case sixty
    case ninety
    case oneTwenty

    var minutes: Int {
        switch self {
        case .thirty:
            return 30
        case .fortyFive:
            return 45
        case .sixty:
            return 60
        case .ninety:
            return 90
        case .oneTwenty:
            return 120
        }
    }

    var label: String {
        "\(minutes) min"
    }

    static func closest(to minutes: Int) -> NotificationIntervalOption {
        let sorted = allCases.sorted { $0.minutes < $1.minutes }
        return sorted.min(by: { abs($0.minutes - minutes) < abs($1.minutes - minutes) }) ?? .ninety
    }
}
