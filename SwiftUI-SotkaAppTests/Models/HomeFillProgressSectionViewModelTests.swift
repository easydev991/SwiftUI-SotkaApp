import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

struct HomeFillProgressSectionViewModelTests {
    private typealias Model = HomeFillProgressSectionView.Model

    @Test("shouldShowFillProgress когда нужно показать")
    func shouldShowFillProgressWhenNeeded() {
        let user = User(id: 1)
        let model = Model(currentDay: 25, user: user)
        #expect(model.shouldShowFillProgress, "У пользователя нет заполненных результатов")
    }

    @Test("shouldShowFillProgress когда не нужно показывать")
    func shouldShowFillProgressWhenNotNeeded() {
        let user = User(id: 1)
        let progress = UserProgress(id: 1)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)

        let model = Model(currentDay: 25, user: user)
        #expect(!model.shouldShowFillProgress)
    }

    @Test(arguments: [1, 25, 48])
    func shouldShowFillProgressWithFilledResultsForBasicBlock(currentDay: Int) {
        let user = User(id: 1)
        let progress = UserProgress(id: 1)
        progress.pullUps = 10
        progress.pushUps = 20
        progress.squats = 30
        progress.weight = 70.0
        user.progressResults.append(progress)

        let model = Model(currentDay: currentDay, user: user)
        #expect(!model.shouldShowFillProgress)
    }

    @Test(arguments: [49, 50, 75, 99])
    func shouldShowFillProgressWithFilledResultsForAdvancedBlock(currentDay: Int) {
        let user = User(id: 1)
        let progress = UserProgress(id: 49)
        progress.pullUps = 15
        progress.pushUps = 25
        progress.squats = 35
        progress.weight = 75.0
        user.progressResults.append(progress)

        let model = Model(currentDay: currentDay, user: user)
        #expect(!model.shouldShowFillProgress)
    }

    @Test
    func shouldShowFillProgressWithFilledResultsForFinalBlock() {
        let user = User(id: 1)
        let progress = UserProgress(id: 100)
        progress.pullUps = 20
        progress.pushUps = 30
        progress.squats = 40
        progress.weight = 80.0
        user.progressResults.append(progress)

        let model = Model(currentDay: 100, user: user)
        #expect(!model.shouldShowFillProgress)
    }

    @Test(arguments: [1, 25, 49, 50, 75, 99, 100, 105])
    func shouldShowFillProgressWithoutResults(currentDay: Int) {
        let user = User(id: 1)
        let model = Model(currentDay: currentDay, user: user)
        #expect(model.shouldShowFillProgress)
    }
}
