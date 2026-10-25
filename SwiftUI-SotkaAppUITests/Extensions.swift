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

@MainActor
extension XCTestCase {
    @discardableResult
    func waitAndTap(timeout: TimeInterval, element: XCUIElement) -> Bool {
        let isElementFound = element.waitForExistence(timeout: timeout)
        if isElementFound {
            element.tapElement()
        }
        return isElementFound
    }

    func waitAndTapOrFail(timeout: TimeInterval = 5, element: XCUIElement) {
        if !waitAndTap(timeout: timeout, element: element) {
            XCTFail("Не нашли элемент \(element)")
        }
    }
}
