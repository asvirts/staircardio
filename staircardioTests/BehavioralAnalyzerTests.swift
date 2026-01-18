//
//  BehavioralAnalyzerTests.swift
//  staircardioTests
//
//  Created by opencode on 2026-01-17.
//

import XCTest
import SwiftData
@testable import staircardio

final class BehavioralAnalyzerTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var analyzer: BehavioralAnalyzer!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: DayLog.self, configurations: configuration)
        context = ModelContext(container)
        analyzer = BehavioralAnalyzer(modelContext: context)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        analyzer = nil
    }

    func testDetectPlateauWithConsistentData() throws {
        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 10, target: 10)
            context.insert(log)
        }
        try context.save()

        let isPlateau = analyzer.detectPlateau(days: 7)
        XCTAssertTrue(isPlateau, "Should detect plateau with consistent data")
    }

    func testDetectNoPlateauWithVariableData() throws {
        let calendar = Calendar.current
        let values = [5, 15, 8, 12, 6, 14, 9]
        for (index, value) in values.enumerated() {
            let date = calendar.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: value, target: 10)
            context.insert(log)
        }
        try context.save()

        let isPlateau = analyzer.detectPlateau(days: 7)
        XCTAssertFalse(isPlateau, "Should not detect plateau with variable data")
    }

    func testDetectPlateauInsufficientData() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 10, target: 10)
        context.insert(log)
        try context.save()

        let isPlateau = analyzer.detectPlateau(days: 7)
        XCTAssertFalse(isPlateau, "Should not detect plateau with insufficient data")
    }

    func testSuggestIncreaseTarget() throws {
        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 12, target: 10)
            context.insert(log)
        }
        try context.save()

        let suggestion = analyzer.suggestTargetAdjustment()
        XCTAssertNotNil(suggestion, "Should suggest target increase")
        XCTAssertTrue(suggestion! > 10, "Suggested target should be higher than current")
    }

    func testSuggestDecreaseTarget() throws {
        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 3, target: 10)
            context.insert(log)
        }
        try context.save()

        let suggestion = analyzer.suggestTargetAdjustment()
        XCTAssertNotNil(suggestion, "Should suggest target decrease")
        XCTAssertTrue(suggestion! < 10, "Suggested target should be lower than current")
    }

    func testNoSuggestionWithGoodTarget() throws {
        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: i % 2 == 0 ? 10 : 9, target: 10)
            context.insert(log)
        }
        try context.save()

        let suggestion = analyzer.suggestTargetAdjustment()
        XCTAssertNil(suggestion, "Should not suggest target adjustment when current is good")
    }

    func testGetPatternAnalysisWithConsistentPerformance() throws {
        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 10, target: 10)
            context.insert(log)
        }
        try context.save()

        let analysis = analyzer.getPatternAnalysis()
        XCTAssertEqual(analysis.pattern, "Consistent performance")
    }

    func testGetPatternAnalysisWithInsufficientData() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 10, target: 10)
        context.insert(log)
        try context.save()

        let analysis = analyzer.getPatternAnalysis()
        XCTAssertEqual(analysis.pattern, "Need more data")
        XCTAssertNil(analysis.bestDay)
        XCTAssertNil(analysis.worstDay)
    }

    func testGetConsistencyScorePerfect() throws {
        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 10, target: 10)
            context.insert(log)
        }
        try context.save()

        let score = analyzer.getConsistencyScore(days: 7)
        XCTAssertEqual(score, 1.0, accuracy: 0.01, "Perfect consistency should be 1.0")
    }

    func testGetConsistencyScorePartial() throws {
        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: i < 3 ? 10 : 5, target: 10)
            context.insert(log)
        }
        try context.save()

        let score = analyzer.getConsistencyScore(days: 7)
        XCTAssertEqual(score, 0.5, accuracy: 0.01, "Partial consistency should be 0.5")
    }

    func testGetWeeklyComparison() throws {
        let calendar = Calendar.current

        let thisWeekLogs = [10, 12, 8, 11, 10, 9, 12]
        for (index, value) in thisWeekLogs.enumerated() {
            let date = calendar.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: value, target: 10)
            context.insert(log)
        }

        let lastWeekLogs = [8, 7, 9, 6, 8, 7, 9]
        for (index, value) in lastWeekLogs.enumerated() {
            let date = calendar.date(byAdding: .day, value: -(7 + index), to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: value, target: 10)
            context.insert(log)
        }

        try context.save()

        let comparison = analyzer.getWeeklyComparison()
        XCTAssertNotNil(comparison)
        XCTAssertEqual(comparison.thisWeekTotal, 72)
        XCTAssertEqual(comparison.lastWeekTotal, 54)
        XCTAssertTrue(comparison.percentChange > 0, "Should show improvement")
    }

    func testGetWeeklyComparisonNoLastWeekData() throws {
        let calendar = Calendar.current
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayKey = dayKeyFromDate(date)
            let log = DayLog(dayKey: dayKey, completed: 10, target: 10)
            context.insert(log)
        }
        try context.save()

        let comparison = analyzer.getWeeklyComparison()
        XCTAssertNotNil(comparison)
        XCTAssertEqual(comparison.thisWeekTotal, 70)
        XCTAssertEqual(comparison.lastWeekTotal, 0)
    }

    func testPatternAnalysisBestDayIdentification() throws {
        let calendar = Calendar.current
        let monday = calendar.date(bySetting: .weekday, value: 2, of: Date()) ?? Date()
        let friday = calendar.date(bySetting: .weekday, value: 6, of: Date()) ?? Date()

        let mondayKey = dayKeyFromDate(monday)
        let fridayKey = dayKeyFromDate(friday)

        let mondayLog = DayLog(dayKey: mondayKey, completed: 15, target: 10)
        let fridayLog = DayLog(dayKey: fridayKey, completed: 5, target: 10)

        context.insert(mondayLog)
        context.insert(fridayLog)
        try context.save()

        let analysis = analyzer.getPatternAnalysis()
        XCTAssertNotNil(analysis.bestDay)
        XCTAssertNotNil(analysis.worstDay)
    }

    private func dayKeyFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
