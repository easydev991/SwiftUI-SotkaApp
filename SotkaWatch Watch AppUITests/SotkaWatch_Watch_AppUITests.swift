import XCTest

@MainActor
final class SotkaWatch_Watch_AppUITests: XCTestCase {
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

    func testMakeScreenshots() throws {
        // TODO: скриншот №2 (тренировка)
        waitAndTapOrFail(element: editActivityButton)
        // TODO: скриншот №3 (превью для тренировки)
        waitAndTapOrFail(element: firstTrainingButton)
        // TODO: скриншот №4 (настройка повторов для упражнения)
        waitAndTapOrFail(element: stepperDoneButton)
        waitAndTapOrFail(element: editWorkoutPreviewButton)
        // TODO: скриншот №5 (редактор упражнений для тренировки)
        waitAndTapOrFail(element: backButton)
        waitAndTapOrFail(element: closeButton)
        waitAndTapOrFail(element: deleteActivityButton)
        waitAndTapOrFail(element: confirmDeleteActivityButton)
        // TODO: скриншот №1 (выбор активности дня)
    }
}

private extension SotkaWatch_Watch_AppUITests {
    var editActivityButton: XCUIElement {
        app.buttons["SelectedActivityView.editButton"].firstMatch
    }

    var firstTrainingButton: XCUIElement {
        app.buttons["WorkoutPreview.trainingRowView"].firstMatch
    }

    var stepperDoneButton: XCUIElement {
        app.buttons["WorkoutStepperView.doneButton"]
    }

    var editWorkoutPreviewButton: XCUIElement {
        app.buttons["WorkoutPreviewView.editButton"].firstMatch
    }

    var backButton: XCUIElement {
        app.buttons["BackButton"]
    }

    var closeButton: XCUIElement {
        app.buttons["xmark"].firstMatch
    }

    var deleteActivityButton: XCUIElement {
        app.buttons["SelectedActivityView.deleteButton"].firstMatch
    }

    var confirmDeleteActivityButton: XCUIElement {
        let ruButton = app.buttons["Удалить"].firstMatch
        let enButton = app.buttons["Delete"].firstMatch
        return ruButton.exists ? ruButton : enButton
    }
}

private extension XCUIElementQuery {
    func element(for localizationKey: String) -> XCUIElement {
        let bundle = Bundle(for: SotkaWatch_Watch_AppUITests.self)
        let localizedString = NSLocalizedString(localizationKey, bundle: bundle, comment: "")
        return self[localizedString]
    }
}
