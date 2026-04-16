import Foundation
@testable import SwiftUI_SotkaApp

@MainActor
final class MockReviewEventReporter: ReviewEventReporting {
    private(set) var reportedContexts: [ReviewContext] = []
    private(set) var callCount = 0

    func workoutCompletedSuccessfully(context: ReviewContext) async {
        callCount += 1
        reportedContexts.append(context)
    }

    func waitForCallCount(_ expected: Int, maxYields: Int = 20) async {
        for _ in 0 ..< maxYields where callCount < expected {
            await Task.yield()
        }
    }
}
