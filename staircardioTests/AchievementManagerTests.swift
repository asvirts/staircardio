//
//  AchievementManagerTests.swift
//  staircardioTests
//
//  Created by opencode on 2026-01-17.
//

import XCTest
import SwiftData
@testable import staircardio

final class AchievementManagerTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var manager: AchievementManager!
    var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: [DayLog.self, Achievement.self], configurations: configuration)
        context = ModelContext(container)
        userDefaults = UserDefaults(suiteName: "TestAchievementManager")!
        userDefaults.removePersistentDomain(forName: "TestAchievementManager")
        manager = AchievementManager(modelContext: context, userDefaults: userDefaults)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        manager = nil
        userDefaults.removePersistentDomain(forName: "TestAchievementManager")
        userDefaults = nil
    }

    func testAchievementInitialization() throws {
        let achievement = Achievement(
            id: UUID(),
            title: "Test Achievement",
            badgeDescription: "Test description",
            badgeType: .streak,
            earnedDate: Date(),
            icon: "star.fill",
            threshold: 10,
            isEarned: true
        )

        XCTAssertEqual(achievement.title, "Test Achievement")
        XCTAssertEqual(achievement.badgeType, .streak)
        XCTAssertTrue(achievement.isEarned)
        XCTAssertEqual(achievement.threshold, 10)
    }

    func testAchievementPersistence() throws {
        let achievement = Achievement(
            id: UUID(),
            title: "First Steps",
            badgeDescription: "Complete 10 total circuits",
            badgeType: .totalCircuits,
            earnedDate: Date(),
            icon: "star.fill",
            threshold: 10,
            isEarned: true
        )

        context.insert(achievement)
        try context.save()

        let descriptor = FetchDescriptor<Achievement>()
        let fetchedAchievements = try context.fetch(descriptor)

        XCTAssertEqual(fetchedAchievements.count, 1)
        XCTAssertEqual(fetchedAchievements.first?.title, "First Steps")
    }

    func testCheckAchievementNotEarned() throws {
        let dayLog = DayLog(dayKey: "2026-01-17", completed: 2, target: 10)
        manager.checkAchievements(dayLog: dayLog)

        XCTAssertTrue(manager.pendingAchievements.isEmpty, "Should not earn achievement with 2-day streak")
    }

    func testCheckAchievementEarned3DayStreak() throws {
        let calendar = Calendar.current
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 10, target: 10)
            context.insert(log)
        }

        let todayLog = DayLog(dayKey: dayKeyFromDate(Date()), completed: 10, target: 10)
        manager.checkAchievements(dayLog: todayLog)

        XCTAssertTrue(manager.pendingAchievements.count > 0, "Should earn 3-day streak achievement")
    }

    func testCheckAchievementEarnedTotalCircuits() throws {
        userDefaults.set(9, forKey: "totalCircuitsEarned")

        let dayLog = DayLog(dayKey: "2026-01-17", completed: 1, target: 10)
        manager.checkAchievements(dayLog: dayLog)

        XCTAssertTrue(manager.pendingAchievements.count > 0, "Should earn achievement for 10 total circuits")
    }

    func testAchievementNotDuplicated() throws {
        let achievement = Achievement(
            id: UUID(),
            title: "3-Day Streak",
            badgeDescription: "Complete your daily target for 3 consecutive days",
            badgeType: .streak,
            earnedDate: Date(),
            icon: "flame.fill",
            threshold: 3,
            isEarned: true
        )

        context.insert(achievement)
        try context.save()

        manager = AchievementManager(modelContext: context, userDefaults: userDefaults)

        let calendar = Calendar.current
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 10, target: 10)
            context.insert(log)
        }

        let todayLog = DayLog(dayKey: dayKeyFromDate(Date()), completed: 10, target: 10)
        manager.checkAchievements(dayLog: todayLog)

        let streakAchievements = manager.pendingAchievements.filter { $0.title == "3-Day Streak" }
        XCTAssertTrue(streakAchievements.isEmpty, "Should not duplicate already earned achievement")
    }

    func testClearPendingAchievements() throws {
        let achievement = Achievement(
            id: UUID(),
            title: "Test Achievement",
            badgeDescription: "Test",
            badgeType: .streak,
            earnedDate: Date(),
            icon: "star.fill",
            threshold: 3,
            isEarned: true
        )

        context.insert(achievement)
        manager.pendingAchievements.append(achievement)

        XCTAssertFalse(manager.pendingAchievements.isEmpty, "Should have pending achievement")

        manager.clearPendingAchievements()

        XCTAssertTrue(manager.pendingAchievements.isEmpty, "Should clear pending achievements")
    }

    func testLoadAllAchievementsProgress() async throws {
        let calendar = Calendar.current
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 10, target: 10)
            context.insert(log)
        }

        userDefaults.set(25, forKey: "totalCircuitsEarned")

        await manager.loadAllAchievementsProgress(dayLogs: [])

        XCTAssertFalse(manager.allAchievementsProgress.isEmpty, "Should load achievement progress")
    }

    func testCalculateCurrentStreak() async throws {
        let calendar = Calendar.current
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 10, target: 10)
            context.insert(log)
        }

        let dayLogs = try context.fetch(FetchDescriptor<DayLog>())
        let streak = manager.calculateCurrentStreak(dayLogs: dayLogs)

        XCTAssertEqual(streak, 5, "Should calculate 5-day streak")
    }

    func testAchievementProgressPercentage() async throws {
        userDefaults.set(5, forKey: "totalCircuitsEarned")

        let dayLogs: [DayLog] = []
        await manager.loadAllAchievementsProgress(dayLogs: dayLogs)

        let tenCircuitAchievement = manager.allAchievementsProgress.first { $0.definition.title == "First Steps" }
        XCTAssertNotNil(tenCircuitAchievement)
        XCTAssertEqual(tenCircuitAchievement?.currentValue, 5)
        XCTAssertEqual(tenCircuitAchievement?.progressPercentage, 0.5, accuracy: 0.01)
    }

    func testAchievementAlreadyEarned() async throws {
        let achievement = Achievement(
            id: UUID(),
            title: "First Steps",
            badgeDescription: "Complete 10 total circuits",
            badgeType: .totalCircuits,
            earnedDate: Date(),
            icon: "star.fill",
            threshold: 10,
            isEarned: true
        )

        context.insert(achievement)
        try context.save()

        manager = AchievementManager(modelContext: context, userDefaults: userDefaults)

        let dayLogs: [DayLog] = []
        await manager.loadAllAchievementsProgress(dayLogs: dayLogs)

        let progress = manager.allAchievementsProgress.first { $0.definition.title == "First Steps" }
        XCTAssertNotNil(progress)
        XCTAssertTrue(progress?.isEarned ?? false)
    }

    func testBadgeTypeEncoding() throws {
        let achievement = Achievement(
            id: UUID(),
            title: "Test",
            badgeDescription: "Test",
            badgeType: .healthImprovement,
            earnedDate: Date(),
            icon: "heart.fill",
            threshold: 50,
            isEarned: true
        )

        XCTAssertEqual(achievement.badgeTypeRaw, "healthImprovement")
        XCTAssertEqual(achievement.badgeType, .healthImprovement)
    }

    func testMultipleAchievementsEarned() throws {
        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 15, target: 10)
            context.insert(log)
        }

        userDefaults.set(100, forKey: "totalCircuitsEarned")

        let todayLog = DayLog(dayKey: dayKeyFromDate(Date()), completed: 15, target: 10)
        manager.checkAchievements(dayLog: todayLog)

        let earnedCount = manager.pendingAchievements.count
        XCTAssertTrue(earnedCount >= 2, "Should earn multiple achievements (7-day streak, 100 circuits)")
    }

    private func dayKeyFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
