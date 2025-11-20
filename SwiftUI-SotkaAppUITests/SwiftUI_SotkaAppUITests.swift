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
        waitAndTapOrFail(timeout: 10, element: todayInfopostButton)
        sleep(3)
        snapshot("1-todayInfopost")
        waitAndTapOrFail(timeout: 5, element: backButton)
        waitAndTapOrFail(timeout: 10, element: todayActivityButton)
        sleep(1)
        snapshot("2-workoutPreview")
        waitAndTapOrFail(timeout: 10, element: openWorkoutEditorButton)
        snapshot("3-workoutEditor")
        waitAndTapOrFail(timeout: 10, element: workoutEditorDoneButton)
        waitAndTapOrFail(timeout: 5, element: closeButton)
        waitAndTapOrFail(timeout: 10, element: profileTabButton)
        waitAndTapOrFail(timeout: 10, element: profileProgressButton)
        snapshot("4-userProgress")
        waitAndTapOrFail(timeout: 5, element: backButton)
        waitAndTapOrFail(timeout: 10, element: profileJournalButton)
        snapshot("5-userJournalGrid")
        waitAndTapOrFail(timeout: 10, element: journalDisplayModeButton)
        waitAndTapOrFail(timeout: 10, element: journalDisplayModeOption)
        snapshot("6-userJournalList")
        waitAndTapOrFail(timeout: 5, element: backButton)
        waitAndTapOrFail(timeout: 10, element: profileExercisesButton)
        snapshot("7-userExercises")
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
    var profileTabButton: XCUIElement { app.buttons["profileTabButton"].firstMatch }
    var closeButton: XCUIElement { app.buttons["closeButton"].firstMatch }
    var backButton: XCUIElement {
        let regularBackButton = app.buttons["BackButton"].firstMatch
        let firstNavBarButton = app.navigationBars.buttons.element(boundBy: 0)
        return regularBackButton.exists ? regularBackButton : firstNavBarButton
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
