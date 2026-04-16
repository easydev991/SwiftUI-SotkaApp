import SwiftUI
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты ReviewRequestTriggerID")
struct ReviewRequestTriggerIDTests {
    @Test("Trigger отличается при смене scenePhase")
    func differsWhenScenePhaseChanges() {
        let inactive = ReviewRequestTriggerID(
            pendingRequest: .first,
            scenePhase: .inactive
        )
        let active = ReviewRequestTriggerID(
            pendingRequest: .first,
            scenePhase: .active
        )

        #expect(inactive != active)
    }

    @Test("Trigger отличается при смене pendingRequest")
    func differsWhenPendingRequestChanges() {
        let first = ReviewRequestTriggerID(
            pendingRequest: .first,
            scenePhase: .active
        )
        let tenth = ReviewRequestTriggerID(
            pendingRequest: .tenth,
            scenePhase: .active
        )

        #expect(first != tenth)
    }
}
