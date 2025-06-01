//
//  SwiftUI_SotkaAppUITests.swift
//  SwiftUI-SotkaAppUITests
//
//  Created by Олег Еременко on 04.05.2025.
//

import XCTest

@MainActor
final class SwiftUI_SotkaAppUITests: XCTestCase {
    private let springBoard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    private var app: XCUIApplication!
    private let login = "testuserapple"
    private let password = "111111"

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
        // TODO: реализовать тесты для скриншотов
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
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
