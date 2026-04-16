import Foundation
import Observation

@MainActor
@Observable
final class ReviewManager: ReviewEventReporting {
    private let attemptStore: any ReviewAttemptStoring
    private let completionsCounter: any WorkoutCompletionsCounting
    private let currentUserIdProvider: @MainActor () -> Int?

    private var didRequestReviewThisSession = false

    private(set) var pendingRequest: ReviewMilestone?
    private(set) var lastSkipReason: ReviewSkipReason?

    init(
        attemptStore: any ReviewAttemptStoring,
        completionsCounter: any WorkoutCompletionsCounting,
        currentUserIdProvider: @MainActor @escaping () -> Int?
    ) {
        self.attemptStore = attemptStore
        self.completionsCounter = completionsCounter
        self.currentUserIdProvider = currentUserIdProvider
    }

    func workoutCompletedSuccessfully(context: ReviewContext) async {
        if didRequestReviewThisSession {
            lastSkipReason = .alreadyAttemptedThisSession
            return
        }
        if context.hadRecentError {
            lastSkipReason = .recentError
            return
        }

        guard let userId = currentUserIdProvider() else {
            lastSkipReason = .noCurrentUser
            return
        }
        let count = await completionsCounter.completedWorkoutCount(currentUserId: userId)

        guard let milestone = ReviewMilestone.milestone(forCompletedWorkoutCount: count) else {
            lastSkipReason = .milestoneNotReached
            return
        }

        let attempted = attemptStore.attemptedMilestones()
        guard ReviewAttemptRules.shouldAttemptMilestone(
            milestone: milestone,
            attemptedMilestones: attempted
        ) else {
            lastSkipReason = .milestoneAlreadyAttempted
            return
        }

        lastSkipReason = nil
        didRequestReviewThisSession = true
        pendingRequest = milestone
    }

    func markConsumed() {
        guard let milestone = pendingRequest else { return }
        attemptStore.markAttempted(milestone)
        pendingRequest = nil
    }
}
