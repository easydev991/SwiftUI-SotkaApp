import StoreKit
import SwiftUI

struct ReviewRequestTriggerID: Hashable {
    let pendingRequest: ReviewMilestone?
    let scenePhase: ScenePhase
}

private struct ReviewRequestModifier: ViewModifier {
    @Environment(ReviewManager.self) private var reviewManager
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    private let launchArguments = ProcessInfo.processInfo.arguments
    private var isReviewRequestSuppressed: Bool {
        launchArguments.contains("-FASTLANE_SNAPSHOT") || launchArguments.contains("UITest")
    }

    let requestDelay: TimeInterval

    func body(content: Content) -> some View {
        if isReviewRequestSuppressed {
            content
        } else {
            content
                .task(id: ReviewRequestTriggerID(
                    pendingRequest: reviewManager.pendingRequest,
                    scenePhase: scenePhase
                )) {
                    guard reviewManager.pendingRequest != nil else { return }
                    await scheduleReviewRequest()
                }
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
