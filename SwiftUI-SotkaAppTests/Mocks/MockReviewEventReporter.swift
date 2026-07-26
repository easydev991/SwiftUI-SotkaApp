import Foundation
@testable import SwiftUI_SotkaApp

@MainActor
final class MockReviewEventReporter: ReviewEventReporting {
    private(set) var reportedHadRecentErrors: [Bool] = []
    private(set) var callCount = 0

    func workoutCompletedSuccessfully(hadRecentError: Bool) async {
        callCount += 1
        reportedHadRecentErrors.append(hadRecentError)
    }

    func waitForCallCount(_ expected: Int, maxYields: Int = 20) async {
        for _ in 0 ..< maxYields where callCount < expected {
            await Task.yield()
        }
    }
}
