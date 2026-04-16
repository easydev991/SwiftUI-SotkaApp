import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты правил review attempts")
struct ReviewAttemptRulesTests {
    @Test("Повторный триггер того же milestone блокируется")
    func blocksRepeatedAttemptForSameMilestone() {
        let canAttempt = ReviewAttemptRules.shouldAttemptMilestone(
            milestone: .tenth,
            attemptedMilestones: [.first, .tenth]
        )

        #expect(!canAttempt)
    }

    @Test("Новый milestone разрешен, если ранее не attempted")
    func allowsAttemptForNewMilestone() {
        let canAttempt = ReviewAttemptRules.shouldAttemptMilestone(
            milestone: .thirtieth,
            attemptedMilestones: [.first, .tenth]
        )

        #expect(canAttempt)
    }
}
