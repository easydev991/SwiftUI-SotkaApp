import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

struct ProgressTests {
    @Test("isFilled с полными данными")
    func isFilledWithCompleteData() {
        let progress = Progress(id: 1)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        #expect(progress.isFilled)
    }

    @Test("isFilled с неполными данными")
    func isFilledWithIncompleteData() {
        let progress = Progress(id: 1)
        progress.pullUps = 10
        progress.pushUps = nil
        progress.squats = 30
        progress.weight = 70.0
        #expect(!progress.isFilled)
    }

    @Test("isFilled с нулевыми значениями")
    func isFilledWithZeroValues() {
        let progress = Progress(id: 1)
        progress.pullUps = 0
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        #expect(!progress.isFilled)
    }

    @Test("isFilled с отрицательными значениями")
    func isFilledWithNegativeValues() {
        let progress = Progress(id: 1)
        progress.pullUps = -5
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        #expect(!progress.isFilled)
    }

    @Test(arguments: [
        (nil, nil, nil, nil),
        (10, nil, nil, nil),
        (10, 20, nil, nil),
        (10, 20, 30, nil),
        (0, 20, 30, 70.0),
        (10, 0, 30, 70.0),
        (10, 20, 0, 70.0),
        (10, 20, 30, 0.0),
        (-1, 20, 30, 70.0),
        (10, -1, 30, 70.0),
        (10, 20, -1, 70.0),
        (10, 20, 30, -1.0)
    ])
    func isFilledParameterized(
        pullUps: Int?,
        pushUps: Int?,
        squats: Int?,
        weight: Float?
    ) {
        let progress = Progress(id: 1)
        progress.pullUps = pullUps
        progress.pushUps = pushUps
        progress.squats = squats
        progress.weight = weight

        #expect(!progress.isFilled)
    }
}
