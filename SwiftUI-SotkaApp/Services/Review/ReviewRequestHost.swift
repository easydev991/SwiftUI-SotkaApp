import StoreKit
import SwiftUI

private struct ReviewRequestModifier: ViewModifier {
    @Environment(ReviewManager.self) private var reviewManager
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    let requestDelay: TimeInterval

    func body(content: Content) -> some View {
        content
            .task(id: reviewManager.pendingRequest) {
                guard reviewManager.pendingRequest != nil else { return }
                await scheduleReviewRequest()
            }
    }

    @MainActor
    private func scheduleReviewRequest() async {
        do {
            try await Task.sleep(for: .seconds(requestDelay))
        } catch {
            return
        }

        guard reviewManager.pendingRequest != nil else { return }
        guard scenePhase == .active else { return }

        requestReview()
        reviewManager.markConsumed()
    }
}

extension View {
    func reviewRequestHandling(requestDelay: TimeInterval = 0.8) -> some View {
        modifier(ReviewRequestModifier(requestDelay: requestDelay))
    }
}
