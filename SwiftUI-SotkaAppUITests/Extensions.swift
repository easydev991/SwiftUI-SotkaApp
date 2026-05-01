import XCTest

extension XCUIElement {
    func tapElement() {
        if isHittable {
            tap()
        } else {
            coordinate(withNormalizedOffset: .init(dx: 0.0, dy: 0.0)).tap()
        }
    }
}

extension XCTestCase {
    @MainActor
    @discardableResult
    func waitAndTap(timeout: TimeInterval, element: XCUIElement) -> Bool {
        let isElementFound = element.waitForExistence(timeout: timeout)
        if isElementFound { element.tapElement() }
        return isElementFound
    }

    @MainActor
    func waitAndTapOrFail(timeout: TimeInterval = 5, element: XCUIElement) {
        if !waitAndTap(timeout: timeout, element: element) {
            XCTFail("Не нашли элемент \(element)")
        }
    }
}
