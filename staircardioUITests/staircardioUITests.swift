//
//  staircardioUITests.swift
//  staircardioUITests
//
//  Created by Andrew Virts on 1/17/26.
//

import XCTest

final class staircardioUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testAddCircuitButtonExists() throws {
        let app = XCUIApplication()
        app.launch()

        let addCircuitButton = app.buttons["+1 Quick Circuit"]
        XCTAssertTrue(addCircuitButton.exists, "Add circuit button should exist")
    }

    @MainActor
    func testAddCircuitButtonTappable() throws {
        let app = XCUIApplication()
        app.launch()

        let addCircuitButton = app.buttons["+1 Quick Circuit"]
        XCTAssertTrue(addCircuitButton.isEnabled, "Add circuit button should be enabled")

        addCircuitButton.tap()

        let updatedProgress = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'out of'")).firstMatch
        XCTAssertTrue(updatedProgress.waitForExistence(timeout: 5), "Progress should update after tapping button")
    }

    @MainActor
    func testStartWorkoutFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let startWorkoutButton = app.buttons["Start Stair Session"]
        if startWorkoutButton.exists {
            startWorkoutButton.tap()

            let workoutActive = app.otherElements.containing(NSPredicate(format: "label CONTAINS 'duration'")).firstMatch
            XCTAssertTrue(workoutActive.exists || !startWorkoutButton.exists, "Workout session should start or be disabled")
        }
    }

    @MainActor
    func testSettingsMenuAccess() throws {
        let app = XCUIApplication()
        app.launch()

        let settingsButton = app.buttons["gearshape"]
        XCTAssertTrue(settingsButton.exists, "Settings button should exist")

        settingsButton.tap()

        let targetTextField = app.textFields["Target circuits"]
        XCTAssertTrue(targetTextField.exists, "Target text field should appear in settings")
    }

    @MainActor
    func testAnalyticsTabAccess() throws {
        let app = XCUIApplication()
        app.launch()

        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.exists, "Analytics tab should exist")

        analyticsTab.tap()

        let weeklySummary = app.buttons["Weekly Summary"]
        XCTAssertTrue(weeklySummary.waitForExistence(timeout: 5), "Weekly summary should appear in analytics")
    }

    @MainActor
    func testHealthTabAccess() throws {
        let app = XCUIApplication()
        app.launch()

        let healthTab = app.tabBars.buttons["Health"]
        XCTAssertTrue(healthTab.exists, "Health tab should exist")

        healthTab.tap()

        let healthDashboard = app.buttons["Health Dashboard"]
        XCTAssertTrue(healthDashboard.waitForExistence(timeout: 5), "Health dashboard should appear in health tab")
    }

    @MainActor
    func testProgressDisplay() throws {
        let app = XCUIApplication()
        app.launch()

        let progressView = app.progressIndicators.firstMatch
        XCTAssertTrue(progressView.exists, "Progress view should be displayed")

        let progressText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '/'")).firstMatch
        XCTAssertTrue(progressText.exists, "Progress text should show completed/total")
    }

    @MainActor
    func testTabBarNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")

        let tabs = ["Today", "Analytics", "Health", "Settings"]
        for tab in tabs {
            let tabButton = app.tabBars.buttons[tab]
            XCTAssertTrue(tabButton.exists, "\(tab) tab should exist")
        }
    }
}
