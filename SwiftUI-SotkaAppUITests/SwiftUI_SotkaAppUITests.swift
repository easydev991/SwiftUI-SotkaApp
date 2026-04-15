import XCTest

@MainActor
final class SwiftUI_SotkaAppUITests: XCTestCase {
    private let springBoard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UITest")
        setupSnapshot(app)
        app.launch()
    }

    override func tearDown() async throws {
        try super.tearDownWithError()
        app.launchArguments.removeAll()
        app = nil
    }

    func testMakeScreenshots() {
        handleNotificationAlert()
        sleep(3)
        snapshot("1-mainScreen")
        waitAndTapOrFail(element: todayInfopostButton)
        sleep(2)
        snapshot("2-todayInfopost")
        waitAndTapOrFail(element: backButton)
        waitAndTapOrFail(element: todayActivityButton)
        sleep(1)
        snapshot("3-workoutPreview")
        waitAndTapOrFail(element: openWorkoutEditorButton)
        snapshot("4-workoutEditor")
        waitAndTapOrFail(element: workoutEditorDoneButton)
        waitAndTapOrFail(element: closeButton)
        waitAndTapOrFail(element: progressTabButton)
        snapshot("5-userProgress")
        waitAndTapOrFail(element: journalTabButton)
        snapshot("6-userJournalGrid")
        waitAndTapOrFail(element: journalDisplayModeButton)
        waitAndTapOrFail(element: journalDisplayModeOption)
        snapshot("7-userJournalList")
        waitAndTapOrFail(element: moreTabButton)
        expandWorkoutSettingsGroup()
        waitAndTapOrFail(element: customExercisesButton)
        snapshot("8-userExercises")
    }
}

private extension SwiftUI_SotkaAppUITests {
    func handleNotificationAlert() {
        let alert = springBoard.alerts.firstMatch
        let button = alert.buttons.element(
            matching: NSPredicate(
                format:
                "label IN {'Allow', 'Разрешить'}"
            )
        )
        waitAndTap(timeout: 5, element: button)
    }
}

private extension SwiftUI_SotkaAppUITests {
    var tabbar: XCUIElement {
        app.tabBars.firstMatch
    }

    var journalTabButton: XCUIElement {
        let regularTabButton = tabbar.buttons.element(boundBy: 1)
        let ipadTabButton = app.buttons["journalTabButton"].firstMatch
        return regularTabButton.exists ? regularTabButton : ipadTabButton
    }

    var progressTabButton: XCUIElement {
        let regularTabButton = tabbar.buttons.element(boundBy: 2)
        let ipadTabButton = app.buttons["progressTabButton"].firstMatch
        return regularTabButton.exists ? regularTabButton : ipadTabButton
    }

    var moreTabButton: XCUIElement {
        let regularTabButton = tabbar.buttons.element(boundBy: 3)
        let ipadTabButton = app.buttons["moreTabButton"].firstMatch
        return regularTabButton.exists ? regularTabButton : ipadTabButton
    }

    var customExercisesButton: XCUIElement {
        app.buttons["customExercisesButton"].firstMatch
    }

    var closeButton: XCUIElement {
        app.buttons["closeButton"].firstMatch
    }

    var backButton: XCUIElement {
        let regularBackButton = app.buttons["BackButton"].firstMatch
        let ipadBackButton = app.navigationBars.buttons.element(boundBy: 0)
        return regularBackButton.exists ? regularBackButton : ipadBackButton
    }

    var todayInfopostButton: XCUIElement {
        app.buttons["TodayInfopostButton"].firstMatch
    }

    var todayActivityButton: XCUIElement {
        app.buttons["TodayActivityButton.0"].firstMatch
    }

    var openWorkoutEditorButton: XCUIElement {
        app.buttons["OpenWorkoutEditorButton"].firstMatch
    }

    var workoutEditorDoneButton: XCUIElement {
        app.buttons["WorkoutEditorDoneButton"].firstMatch
    }

    var journalDisplayModeButton: XCUIElement {
        app.buttons["JournalDisplayModeButton"].firstMatch
    }

    var journalDisplayModeOption: XCUIElement {
        app.buttons["JournalDisplayModeOption.0"].firstMatch
    }

    func expandWorkoutSettingsGroup() {
        let workoutGroup = app.buttons["moreScreenWorkoutGroup"].firstMatch
        if !customExercisesButton.waitForExistence(timeout: 1), workoutGroup.exists {
            workoutGroup.tap()
        }
    }
}

private extension XCUIElementQuery {
    func element(for localizationKey: String) -> XCUIElement {
        let bundle = Bundle(for: SwiftUI_SotkaAppUITests.self)
        let localizedString = NSLocalizedString(localizationKey, bundle: bundle, comment: "")
        return self[localizedString]
    }
}
