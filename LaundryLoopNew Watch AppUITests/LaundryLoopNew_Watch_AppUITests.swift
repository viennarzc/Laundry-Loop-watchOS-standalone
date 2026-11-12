import XCTest

final class LaundryLoopNew_Watch_AppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testStartPauseResumeAndAddTime() {
        let app = launchApp()
        XCTAssertTrue(app.buttons["start-washer-button"].waitForExistence(timeout: 10))
        app.buttons["start-washer-button"].tap()
        let pause = app.buttons["pause-resume-button"]
        reveal(pause, in: app)
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        pause.tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
        app.buttons["add-five-button"].tap()
        app.buttons["pause-resume-button"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testStartDryerFromHome() {
        let app = launchApp()
        let button = app.buttons["start-dryer-button"]
        reveal(button, in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()
        XCTAssertTrue(app.buttons["pause-resume-button"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCompletedWasherStartsDryer() {
        let app = launchApp(seedCompletedWasher: true)
        let startDryer = app.buttons["start-dryer-complete-button"]
        reveal(startDryer, in: app)
        XCTAssertTrue(startDryer.waitForExistence(timeout: 10))
        startDryer.tap()
        XCTAssertTrue(app.buttons["pause-resume-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Dryer"].exists)
    }

    @MainActor
    func testCompletedWasherCanSnoozeOrFinish() {
        let app = launchApp(seedCompletedWasher: true)
        let snooze = app.buttons["snooze-button"]
        reveal(snooze, in: app)
        XCTAssertTrue(snooze.waitForExistence(timeout: 10))
        snooze.tap()
        XCTAssertTrue(app.staticTexts["Snoozed"].waitForExistence(timeout: 5))
        let finish = app.buttons["finish-button"]
        reveal(finish, in: app)
        finish.tap()
        let finishChoices = app.buttons.matching(NSPredicate(format: "label == %@", "Finish")).allElementsBoundByIndex
        XCTAssertFalse(finishChoices.isEmpty)
        finishChoices.last?.tap()
        XCTAssertTrue(app.buttons["start-washer-button"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testProfilePersistsAfterRelaunch() {
        let app = launchApp()
        openSettings(in: app)
        let picker = app.buttons["reminder-profile-picker"].firstMatch
        reveal(picker, in: app)
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        app.buttons["Gentle"].tap()
        XCTAssertTrue(app.staticTexts["Completion alert only."].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--uitesting"]
        app.launch()
        openSettings(in: app)
        XCTAssertTrue(app.staticTexts["Completion alert only."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDeniedNotificationsExplainHowToEnableThem() {
        let app = launchApp(denied: true)
        openSettings(in: app)
        let guidance = app.staticTexts["Notifications are turned off for Laundry Loop. Enable them in Apple Watch settings if you want completion reminders."]
        reveal(guidance, in: app)
        XCTAssertTrue(guidance.waitForExistence(timeout: 5))
    }

    @MainActor
    private func launchApp(seedCompletedWasher: Bool = false, denied: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["LAUNDRY_LOOP_UI_TEST_ID"] = UUID().uuidString
        app.launchArguments = ["--uitesting", "--uitesting-reset"]
        if seedCompletedWasher { app.launchArguments.append("--uitesting-seed-completed-washer") }
        if denied { app.launchArguments.append("--uitesting-denied") }
        app.launch()
        return app
    }

    @MainActor
    private func openSettings(in app: XCUIApplication) {
        let button = app.buttons["Settings"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<4 where !element.isHittable {
            app.swipeUp()
        }
    }
}
