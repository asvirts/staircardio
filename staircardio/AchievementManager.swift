import Foundation
import SwiftData
import Combine
import HealthKit

@MainActor
final class AchievementManager: ObservableObject {
    @Published var earnedAchievements: [Achievement] = []
    @Published var pendingAchievements: [Achievement] = []
    @Published var allAchievementsProgress: [AchievementProgress] = []

    private let modelContext: ModelContext
    private let userDefaults: UserDefaults
    private let achievementDefinitions: [AchievementDefinition]
    private let healthKitManager: HealthKitManager?

    private let totalCircuitsEarnedKey = "totalCircuitsEarned"
    private let currentStreakKey = "currentStreak"

    init(modelContext: ModelContext, userDefaults: UserDefaults = .standard, healthKitManager: HealthKitManager? = nil) {
        self.modelContext = modelContext
        self.userDefaults = userDefaults
        self.healthKitManager = healthKitManager
        self.achievementDefinitions = Self.allAchievementDefinitions()

        loadAchievements()
    }

    func checkAchievements(dayLog: DayLog) {
        var newAchievements: [Achievement] = []

        updateTotalCircuits(dayLog.completed)

        let totalCircuits = getTotalCircuits()
        let currentStreak = getCurrentStreak()

        for definition in achievementDefinitions {
            if !isEarned(definition) {
                if definition.checkCondition(totalCircuits, currentStreak, dayLog) {
                    let achievement = createAchievement(from: definition)
                    modelContext.insert(achievement)
                    newAchievements.append(achievement)
                }
            }
        }

        if !newAchievements.isEmpty {
            do {
                try modelContext.save()
            } catch {
                print("Failed to save achievements: \(error)")
            }
        }

        pendingAchievements.append(contentsOf: newAchievements)
        earnedAchievements.append(contentsOf: newAchievements)
    }

    func checkHealthAchievements(vo2Max: Double?, restingHeartRate: Double?) {
        var newAchievements: [Achievement] = []

        for definition in achievementDefinitions {
            if definition.type == .healthImprovement, !isEarned(definition) {
                if definition.checkHealthCondition(vo2Max, restingHeartRate) {
                    let achievement = createAchievement(from: definition)
                    modelContext.insert(achievement)
                    newAchievements.append(achievement)
                }
            }
        }

        if !newAchievements.isEmpty {
            do {
                try modelContext.save()
            } catch {
                print("Failed to save achievements: \(error)")
            }
        }

        pendingAchievements.append(contentsOf: newAchievements)
        earnedAchievements.append(contentsOf: newAchievements)
    }

    func clearPendingAchievements() {
        pendingAchievements = []
    }

    func loadAllAchievementsProgress(dayLogs: [DayLog]) async {
        var progressList: [AchievementProgress] = []

        let totalCircuits = getTotalCircuits()
        let currentStreak = calculateCurrentStreak(dayLogs: dayLogs)
        let latestVO2Max = await getLatestVO2Max()
        let latestRHR = await getLatestRestingHeartRate()

        for definition in achievementDefinitions {
            let earned = isEarned(definition)
            var currentValue = 0
            var progressPercentage = 0.0
            var healthValue: Double? = nil

            switch definition.type {
            case .streak:
                currentValue = currentStreak
                progressPercentage = min(Double(currentValue) / Double(definition.threshold), 1.0)
            case .totalCircuits:
                currentValue = totalCircuits
                progressPercentage = min(Double(currentValue) / Double(definition.threshold), 1.0)
            case .healthImprovement:
                if definition.title.contains("VO₂") {
                    if let vo2Max = latestVO2Max {
                        healthValue = vo2Max
                        progressPercentage = min(vo2Max / Double(definition.threshold), 1.0)
                    }
                } else if definition.title.contains("Heart") {
                    if let rhr = latestRHR {
                        healthValue = rhr
                        let threshold = Double(definition.threshold)
                        if rhr < threshold {
                            progressPercentage = 1.0
                        } else {
                            progressPercentage = max(0.0, 1.0 - ((rhr - threshold) / 20.0))
                        }
                    }
                }
            case .consistency:
                progressPercentage = 0.0
            }

            progressList.append(AchievementProgress(
                definition: definition,
                isEarned: earned,
                currentValue: currentValue,
                progressPercentage: progressPercentage,
                healthValue: healthValue
            ))
        }

        let earnedFirst = progressList.sorted { a, b in
            if a.isEarned != b.isEarned {
                return a.isEarned && !b.isEarned
            }
            if !a.isEarned && !b.isEarned {
                return a.progressPercentage > b.progressPercentage
            }
            return false
        }

        allAchievementsProgress = earnedFirst
    }

    func calculateCurrentStreak(dayLogs: [DayLog]) -> Int {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let sortedLogs = dayLogs.sorted { $0.dayKey > $1.dayKey }
        var streak = 0
        var currentDate = today

        for _ in sortedLogs {
            let logKey = dateFormatter.string(from: currentDate)
            if let todayLog = sortedLogs.first(where: { $0.dayKey == logKey }) {
                if todayLog.completed >= todayLog.target {
                    streak += 1
                    currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            } else {
                break
            }
        }

        return streak
    }

    private func getLatestVO2Max() async -> Double? {
        guard let healthKitManager = healthKitManager else { return nil }
        let samples = await healthKitManager.fetchVO2MaxSamples(limit: 1)
        return samples.first?.value
    }

    private func getLatestRestingHeartRate() async -> Double? {
        guard let healthKitManager = healthKitManager else { return nil }
        let samples = await healthKitManager.fetchRestingHeartRateSamples(limit: 1)
        return samples.first?.value
    }

    private func loadAchievements() {
        let descriptor = FetchDescriptor<Achievement>(sortBy: [SortDescriptor(\.earnedDate, order: .reverse)])
        earnedAchievements = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func isEarned(_ definition: AchievementDefinition) -> Bool {
        return earnedAchievements.contains { achievement in
            achievement.title == definition.title &&
            achievement.badgeTypeRaw == definition.type.rawValue
        }
    }

    private func createAchievement(from definition: AchievementDefinition) -> Achievement {
        return Achievement(
            id: UUID(),
            title: definition.title,
            badgeDescription: definition.badgeDescription,
            badgeType: definition.type,
            earnedDate: Date(),
            icon: definition.icon,
            threshold: definition.threshold,
            isEarned: true
        )
    }

    private func updateTotalCircuits(_ todayCircuits: Int) {
        let currentTotal = getTotalCircuits()
        userDefaults.set(currentTotal + todayCircuits, forKey: totalCircuitsEarnedKey)
    }

    private func getTotalCircuits() -> Int {
        userDefaults.integer(forKey: totalCircuitsEarnedKey)
    }

    private func getCurrentStreak() -> Int {
        userDefaults.integer(forKey: currentStreakKey)
    }

    private static func allAchievementDefinitions() -> [AchievementDefinition] {
        return [
            StreakAchievement(threshold: 3, type: .streak, title: "3-Day Streak", badgeDescription: "Complete your daily target for 3 consecutive days", icon: "flame.fill").achievementDefinition,
            StreakAchievement(threshold: 7, type: .streak, title: "Week Warrior", badgeDescription: "Complete your daily target for 7 consecutive days", icon: "flame.fill").achievementDefinition,
            StreakAchievement(threshold: 14, type: .streak, title: "Two-Week Streak", badgeDescription: "Complete your daily target for 14 consecutive days", icon: "flame.fill").achievementDefinition,
            StreakAchievement(threshold: 30, type: .streak, title: "Month Master", badgeDescription: "Complete your daily target for 30 consecutive days", icon: "flame.fill").achievementDefinition,

            TotalCircuitsAchievement(threshold: 10, type: .totalCircuits, title: "First Steps", badgeDescription: "Complete 10 total circuits", icon: "star.fill").achievementDefinition,
            TotalCircuitsAchievement(threshold: 50, type: .totalCircuits, title: "Climbing Up", badgeDescription: "Complete 50 total circuits", icon: "star.fill").achievementDefinition,
            TotalCircuitsAchievement(threshold: 100, type: .totalCircuits, title: "Century", badgeDescription: "Complete 100 total circuits", icon: "star.fill").achievementDefinition,
            TotalCircuitsAchievement(threshold: 500, type: .totalCircuits, title: "Stair Master", badgeDescription: "Complete 500 total circuits", icon: "star.fill").achievementDefinition,
            TotalCircuitsAchievement(threshold: 1000, type: .totalCircuits, title: "Legend", badgeDescription: "Complete 1,000 total circuits", icon: "star.fill").achievementDefinition,

            ConsistencyAchievement(threshold: 5, type: .consistency, title: "Consistent Starter", badgeDescription: "Hit your daily target on 5 days", icon: "checkmark.circle.fill").achievementDefinition,
            ConsistencyAchievement(threshold: 20, type: .consistency, title: "Weekly Champion", badgeDescription: "Hit your daily target on 20 days", icon: "checkmark.circle.fill").achievementDefinition,
            ConsistencyAchievement(threshold: 50, type: .consistency, title: "Consistency Pro", badgeDescription: "Hit your daily target on 50 days", icon: "checkmark.circle.fill").achievementDefinition,

            VO2MaxAchievement(threshold: 45, type: .healthImprovement, title: "Fit Start", badgeDescription: "Reach a VO₂ max of 45 ml/kg·min", icon: "heart.fill").achievementDefinition,
            VO2MaxAchievement(threshold: 50, type: .healthImprovement, title: "Above Average", badgeDescription: "Reach a VO₂ max of 50 ml/kg·min", icon: "heart.fill").achievementDefinition,
            VO2MaxAchievement(threshold: 55, type: .healthImprovement, title: "Excellent Fitness", badgeDescription: "Reach a VO₂ max of 55 ml/kg·min", icon: "heart.fill").achievementDefinition,

            RHRImprovementAchievement(threshold: 60, type: .healthImprovement, title: "Strong Heart", badgeDescription: "Achieve a resting heart rate below 60 bpm", icon: "heart.fill").achievementDefinition,
            RHRImprovementAchievement(threshold: 50, type: .healthImprovement, title: "Elite Athlete", badgeDescription: "Achieve a resting heart rate below 50 bpm", icon: "heart.fill").achievementDefinition
        ]
    }
}

struct AchievementDefinition {
    let type: BadgeType
    let title: String
    let badgeDescription: String
    let icon: String
    let threshold: Int
    let checkCondition: (Int, Int, DayLog) -> Bool
    let checkHealthCondition: (Double?, Double?) -> Bool

    init(
        type: BadgeType,
        title: String,
        badgeDescription: String,
        icon: String,
        threshold: Int,
        checkCondition: @escaping (Int, Int, DayLog) -> Bool,
        checkHealthCondition: @escaping (Double?, Double?) -> Bool = { _, _ in false }
    ) {
        self.type = type
        self.title = title
        self.badgeDescription = badgeDescription
        self.icon = icon
        self.threshold = threshold
        self.checkCondition = checkCondition
        self.checkHealthCondition = checkHealthCondition
    }
}

struct StreakAchievement {
    let threshold: Int
    let type: BadgeType
    let title: String
    let badgeDescription: String
    let icon: String

    var achievementDefinition: AchievementDefinition {
        AchievementDefinition(
            type: type,
            title: title,
            badgeDescription: badgeDescription,
            icon: icon,
            threshold: threshold,
            checkCondition: { _, currentStreak, _ in
                currentStreak >= threshold
            }
        )
    }
}

struct TotalCircuitsAchievement {
    let threshold: Int
    let type: BadgeType
    let title: String
    let badgeDescription: String
    let icon: String

    var achievementDefinition: AchievementDefinition {
        AchievementDefinition(
            type: type,
            title: title,
            badgeDescription: badgeDescription,
            icon: icon,
            threshold: threshold,
            checkCondition: { totalCircuits, _, _ in
                totalCircuits >= threshold
            }
        )
    }
}

struct ConsistencyAchievement {
    let threshold: Int
    let type: BadgeType
    let title: String
    let badgeDescription: String
    let icon: String

    var achievementDefinition: AchievementDefinition {
        AchievementDefinition(
            type: type,
            title: title,
            badgeDescription: badgeDescription,
            icon: icon,
            threshold: threshold,
            checkCondition: { _, _, _ in false }
        )
    }
}

struct VO2MaxAchievement {
    let threshold: Int
    let type: BadgeType
    let title: String
    let badgeDescription: String
    let icon: String

    var achievementDefinition: AchievementDefinition {
        AchievementDefinition(
            type: type,
            title: title,
            badgeDescription: badgeDescription,
            icon: icon,
            threshold: threshold,
            checkCondition: { _, _, _ in false },
            checkHealthCondition: { vo2Max, _ in
                guard let vo2Max else { return false }
                return vo2Max >= Double(threshold)
            }
        )
    }
}

struct RHRImprovementAchievement {
    let threshold: Int
    let type: BadgeType
    let title: String
    let badgeDescription: String
    let icon: String

    var achievementDefinition: AchievementDefinition {
        AchievementDefinition(
            type: type,
            title: title,
            badgeDescription: badgeDescription,
            icon: icon,
            threshold: threshold,
            checkCondition: { _, _, _ in false },
            checkHealthCondition: { _, restingHeartRate in
                guard let rhr = restingHeartRate else { return false }
                return rhr < Double(threshold)
            }
        )
    }
}

struct AchievementProgress {
    let definition: AchievementDefinition
    let isEarned: Bool
    let currentValue: Int
    let progressPercentage: Double
    let healthValue: Double?
}
