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
        waitAndTapOrFail(element: profileTabButton)
        waitAndTapOrFail(element: profileProgressButton)
        snapshot("5-userProgress")
        waitAndTapOrFail(element: backButton)
        waitAndTapOrFail(element: profileJournalButton)
        snapshot("6-userJournalGrid")
        waitAndTapOrFail(element: journalDisplayModeButton)
        waitAndTapOrFail(element: journalDisplayModeOption)
        snapshot("7-userJournalList")
        waitAndTapOrFail(element: backButton)
        waitAndTapOrFail(element: profileExercisesButton)
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
    var tabbar: XCUIElement { app.tabBars.firstMatch }
    var profileTabButton: XCUIElement {
        let regularProfileTabButton = tabbar.buttons.element(boundBy: 1)
        let ipadProfileTabButton = app.buttons["profileTabButton"].firstMatch
        return regularProfileTabButton.exists ? regularProfileTabButton : ipadProfileTabButton
    }

    var closeButton: XCUIElement { app.buttons["closeButton"].firstMatch }
    var backButton: XCUIElement {
        let regularBackButton = app.buttons["BackButton"].firstMatch
        let ipadBackButton = app.navigationBars.buttons.element(boundBy: 0)
        return regularBackButton.exists ? regularBackButton : ipadBackButton
    }

    var todayInfopostButton: XCUIElement { app.buttons["TodayInfopostButton"].firstMatch }
    var todayActivityButton: XCUIElement { app.buttons["TodayActivityButton.0"].firstMatch }
    var openWorkoutEditorButton: XCUIElement { app.buttons["OpenWorkoutEditorButton"].firstMatch }
    var workoutEditorDoneButton: XCUIElement { app.buttons["WorkoutEditorDoneButton"].firstMatch }
    var profileProgressButton: XCUIElement { app.buttons["ProfileProgressButton"].firstMatch }
    var profileJournalButton: XCUIElement { app.buttons["ProfileJournalButton"].firstMatch }
    var journalDisplayModeButton: XCUIElement { app.buttons["JournalDisplayModeButton"].firstMatch }
    var journalDisplayModeOption: XCUIElement { app.buttons["JournalDisplayModeOption.0"].firstMatch }
    var profileExercisesButton: XCUIElement { app.buttons["ProfileExercisesButton"].firstMatch }
}

private extension XCUIElementQuery {
    func element(for localizationKey: String) -> XCUIElement {
        let bundle = Bundle(for: SwiftUI_SotkaAppUITests.self)
        let localizedString = NSLocalizedString(localizationKey, bundle: bundle, comment: "")
        return self[localizedString]
    }
}
