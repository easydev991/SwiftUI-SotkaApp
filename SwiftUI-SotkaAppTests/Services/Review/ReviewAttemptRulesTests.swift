import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты правил review attempts")
struct ReviewAttemptRulesTests {
    @Test("Повторный триггер того же milestone блокируется")
    func blocksRepeatedAttemptForSameMilestone() {
        #expect(!ReviewMilestone.tenth.isNotYetAttempted(in: [.first, .tenth]))
    }

    @Test("Новый milestone разрешен, если ранее не attempted")
    func allowsAttemptForNewMilestone() {
        #expect(ReviewMilestone.thirtieth.isNotYetAttempted(in: [.first, .tenth]))
    }
}
