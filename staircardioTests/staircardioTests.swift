//
//  staircardioTests.swift
//  staircardioTests
//
//  Created by Andrew Virts on 1/17/26.
//

import XCTest
import SwiftData
@testable import staircardio

final class staircardioTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: [DayLog.self, WorkoutLog.self, Achievement.self], configurations: configuration)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func testDayLogInitialization() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 5, target: 10)

        XCTAssertEqual(log.dayKey, "2026-01-17")
        XCTAssertEqual(log.completed, 5)
        XCTAssertEqual(log.target, 10)
    }

    func testDayLogDefaultValues() throws {
        let log = DayLog(dayKey: "2026-01-17")

        XCTAssertEqual(log.completed, 0)
        XCTAssertEqual(log.target, 10)
    }

    func testDayLogPersistence() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 7, target: 10)
        context.insert(log)

        let descriptor = FetchDescriptor<DayLog>()
        let fetchedLogs = try context.fetch(descriptor)

        XCTAssertEqual(fetchedLogs.count, 1)
        XCTAssertEqual(fetchedLogs.first?.completed, 7)
        XCTAssertEqual(fetchedLogs.first?.target, 10)
    }

    func testDayLogUpdateAndSave() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 3, target: 8)
        context.insert(log)
        try context.save()

        log.completed += 1
        try context.save()

        let descriptor = FetchDescriptor<DayLog>()
        let fetchedLogs = try context.fetch(descriptor)

        XCTAssertEqual(fetchedLogs.first?.completed, 4)
    }

    func testDayLogMultipleDays() throws {
        let today = DayLog(dayKey: "2026-01-17", completed: 10, target: 10)
        let yesterday = DayLog(dayKey: "2026-01-16", completed: 8, target: 10)
        
        context.insert(today)
        context.insert(yesterday)
        try context.save()

        let descriptor = FetchDescriptor<DayLog>()
        let fetchedLogs = try context.fetch(descriptor)

        XCTAssertEqual(fetchedLogs.count, 2)
    }

    func testDayKeyFormat() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = Date()
        let dayKey = formatter.string(from: date)

        XCTAssertTrue(dayKey.count == 10)
        XCTAssertTrue(dayKey.contains("-"))

        let components = dayKey.components(separatedBy: "-")
        XCTAssertEqual(components.count, 3)
    }

    func testTodayKeyStatic() throws {
        let todayKey = ContentView.todayKey

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let expected = formatter.string(from: Date())

        XCTAssertEqual(todayKey, expected)
    }

    func testProgressCalculation() throws {
        let log1 = DayLog(dayKey: "2026-01-17", completed: 5, target: 10)
        let progress1 = Double(log1.completed) / Double(log1.target)

        XCTAssertEqual(progress1, 0.5)

        let log2 = DayLog(dayKey: "2026-01-17", completed: 10, target: 10)
        let progress2 = Double(log2.completed) / Double(log2.target)

        XCTAssertEqual(progress2, 1.0)
    }

    func testProgressWithZeroTarget() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 5, target: 0)
        let progress = log.target > 0 ? Double(log.completed) / Double(log.target) : 0

        XCTAssertEqual(progress, 0)
    }

    func testGoalReached() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 10, target: 10)
        let isGoalReached = log.completed >= log.target

        XCTAssertTrue(isGoalReached)
    }

    func testGoalNotReached() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 5, target: 10)
        let isGoalReached = log.completed >= log.target

        XCTAssertFalse(isGoalReached)
    }

    func testRemainingCircuits() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 5, target: 10)
        let remaining = log.target - log.completed

        XCTAssertEqual(remaining, 5)
    }

    func testRemainingWhenGoalReached() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 10, target: 10)
        let remaining = log.target - log.completed

        XCTAssertEqual(remaining, 0)
    }

    func testIncrementCompleted() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 5, target: 10)
        log.completed += 1

        XCTAssertEqual(log.completed, 6)
    }

    func testResetCompleted() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 10, target: 10)
        log.completed = 0

        XCTAssertEqual(log.completed, 0)
    }

    func testChangeTarget() throws {
        let log = DayLog(dayKey: "2026-01-17", completed: 5, target: 10)
        log.target = 15

        XCTAssertEqual(log.target, 15)
    }

    func testPerformanceExample() throws {
        self.measure {
            let log = DayLog(dayKey: "2026-01-17", completed: 5, target: 10)
            _ = Double(log.completed) / Double(log.target)
        }
    }

    func testWorkoutLogInitialization() throws {
        let uuid = UUID()
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(300)
        let log = WorkoutLog(
            workoutUUID: uuid,
            startDate: startDate,
            endDate: endDate,
            duration: 300,
            floors: 12.0,
            activeEnergy: 150.5,
            averageHeartRate: 120.0,
            circuits: 3
        )

        XCTAssertEqual(log.workoutUUID, uuid)
        XCTAssertEqual(log.startDate, startDate)
        XCTAssertEqual(log.endDate, endDate)
        XCTAssertEqual(log.duration, 300)
        XCTAssertEqual(log.floors, 12.0)
        XCTAssertEqual(log.activeEnergy, 150.5)
        XCTAssertEqual(log.averageHeartRate, 120.0)
        XCTAssertEqual(log.circuits, 3)
        XCTAssertNil(log.appliedDayKey)
    }

    func testWorkoutLogWithAppliedDayKey() throws {
        let log = WorkoutLog(
            workoutUUID: UUID(),
            startDate: Date(),
            endDate: Date(),
            duration: 300,
            floors: 12.0,
            activeEnergy: 150.5,
            averageHeartRate: 120.0,
            circuits: 3,
            appliedDayKey: "2026-01-17"
        )

        XCTAssertEqual(log.appliedDayKey, "2026-01-17")
    }

    func testWorkoutLogPersistence() throws {
        let uuid = UUID()
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(300)

        let log = WorkoutLog(
            workoutUUID: uuid,
            startDate: startDate,
            endDate: endDate,
            duration: 300,
            floors: 12.0,
            activeEnergy: 150.5,
            averageHeartRate: 120.0,
            circuits: 3
        )

        context.insert(log)
        try context.save()

        let descriptor = FetchDescriptor<WorkoutLog>()
        let fetchedLogs = try context.fetch(descriptor)

        XCTAssertEqual(fetchedLogs.count, 1)
        XCTAssertEqual(fetchedLogs.first?.workoutUUID, uuid)
        XCTAssertEqual(fetchedLogs.first?.floors, 12.0)
        XCTAssertEqual(fetchedLogs.first?.circuits, 3)
    }

    func testWorkoutLogDurationCalculation() throws {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(600)
        let duration = endDate.timeIntervalSince(startDate)

        XCTAssertEqual(duration, 600)
    }

    func testWorkoutLogCircuitsFromFloors() throws {
        let floorsPerCircuit = 4.0
        let floors = 12.0
        let circuits = Int((floors / floorsPerCircuit).rounded(.down))

        XCTAssertEqual(circuits, 3)
    }

    func testWorkoutLogZeroFloors() throws {
        let log = WorkoutLog(
            workoutUUID: UUID(),
            startDate: Date(),
            endDate: Date(),
            duration: 300,
            floors: 0.0,
            activeEnergy: 0.0,
            averageHeartRate: 0.0,
            circuits: 0
        )

        XCTAssertEqual(log.floors, 0.0)
        XCTAssertEqual(log.circuits, 0)
    }

    func testWorkoutLogMultipleLogs() throws {
        let log1 = WorkoutLog(
            workoutUUID: UUID(),
            startDate: Date(),
            endDate: Date(),
            duration: 300,
            floors: 12.0,
            activeEnergy: 150.5,
            averageHeartRate: 120.0,
            circuits: 3
        )

        let log2 = WorkoutLog(
            workoutUUID: UUID(),
            startDate: Date(),
            endDate: Date(),
            duration: 400,
            floors: 16.0,
            activeEnergy: 200.5,
            averageHeartRate: 125.0,
            circuits: 4
        )

        context.insert(log1)
        context.insert(log2)
        try context.save()

        let descriptor = FetchDescriptor<WorkoutLog>()
        let fetchedLogs = try context.fetch(descriptor)

        XCTAssertEqual(fetchedLogs.count, 2)
    }

    func testWorkoutLogDefaultValues() throws {
        let log = WorkoutLog(
            workoutUUID: UUID(),
            startDate: Date(),
            endDate: Date(),
            duration: 300,
            floors: 12.0,
            activeEnergy: 150.5,
            averageHeartRate: 120.0,
            circuits: 3
        )

        XCTAssertNotNil(log.id)
        XCTAssertNotNil(log.workoutUUID)
    }

    func testWorkoutLogFetchByUUID() throws {
        let uuid = UUID()
        let log = WorkoutLog(
            workoutUUID: uuid,
            startDate: Date(),
            endDate: Date(),
            duration: 300,
            floors: 12.0,
            activeEnergy: 150.5,
            averageHeartRate: 120.0,
            circuits: 3
        )

        context.insert(log)
        try context.save()

        let descriptor = FetchDescriptor<WorkoutLog>(
            predicate: #Predicate { $0.workoutUUID == uuid }
        )
        let fetchedLogs = try context.fetch(descriptor)

        XCTAssertEqual(fetchedLogs.count, 1)
        XCTAssertEqual(fetchedLogs.first?.workoutUUID, uuid)
    }

}
