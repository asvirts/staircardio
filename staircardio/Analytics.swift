import Foundation
import SwiftData

@Model
final class DailyStats {
    var dayKey: String = ""
    var completed: Int = 0
    var target: Int = 0
    var workoutCount: Int = 0

    init(
        dayKey: String,
        completed: Int = 0,
        target: Int = 0,
        workoutCount: Int = 0
    ) {
        self.dayKey = dayKey
        self.completed = completed
        self.target = target
        self.workoutCount = workoutCount
    }

    var completionRate: Double {
        guard target > 0 else { return 0 }
        return Double(completed) / Double(target)
    }

    var isGoalMet: Bool {
        completed >= target
    }
}

struct WeeklyStats {
    var totalCircuits: Int = 0
    var completionRate: Double = 0
    var streakDays: Int = 0
    var bestDay: DailyStats?
    var averageCircuitsPerDay: Double = 0

    init(
        totalCircuits: Int = 0,
        completionRate: Double = 0,
        streakDays: Int = 0,
        bestDay: DailyStats? = nil,
        averageCircuitsPerDay: Double = 0
    ) {
        self.totalCircuits = totalCircuits
        self.completionRate = completionRate
        self.streakDays = streakDays
        self.bestDay = bestDay
        self.averageCircuitsPerDay = averageCircuitsPerDay
    }
}

struct StreakInfo {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCompletedDate: Date?

    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletedDate: Date? = nil
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletedDate = lastCompletedDate
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case seven = "7"
    case fourteen = "14"
    case thirty = "30"
    case sixty = "60"
    case ninety = "90"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .seven: return 7
        case .fourteen: return 14
        case .thirty: return 30
        case .sixty: return 60
        case .ninety: return 90
        }
    }

    var label: String {
        switch self {
        case .seven: return "7 Days"
        case .fourteen: return "14 Days"
        case .thirty: return "30 Days"
        case .sixty: return "60 Days"
        case .ninety: return "90 Days"
        }
    }
}
