import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты правил review attempts")
struct ReviewAttemptRulesTests {
    @Test("Повторный триггер того же milestone блокируется")
    func blocksRepeatedAttemptForSameMilestone() {
        let canAttempt = ReviewManager.shouldAttemptMilestone(
            milestone: .tenth,
            attemptedMilestones: [.first, .tenth]
        )

        #expect(!canAttempt)
    }

    @Test("Новый milestone разрешен, если ранее не attempted")
    func allowsAttemptForNewMilestone() {
        let canAttempt = ReviewManager.shouldAttemptMilestone(
            milestone: .thirtieth,
            attemptedMilestones: [.first, .tenth]
        )

        #expect(canAttempt)
    }
}
