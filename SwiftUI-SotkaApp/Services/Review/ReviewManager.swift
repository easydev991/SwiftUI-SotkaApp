import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class ReviewManager: ReviewEventReporting {
    enum ReviewSkipReason: Equatable {
        case alreadyAttemptedThisSession
        case recentError
        case noCurrentUser
        case milestoneNotReached
        case milestoneAlreadyAttempted
    }

    private let attemptStore: any ReviewAttemptStoring
    private let completionsCounter: any WorkoutCompletionsCounting
    private let currentUserIdProvider: @MainActor () -> Int?

    @ObservationIgnored private let logger = Logger(
        subsystem: "SotkaApp",
        category: String(describing: ReviewManager.self)
    )

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
            logger.info("Review пропущено: повтор в текущей сессии")
            return
        }
        if context.hadRecentError {
            lastSkipReason = .recentError
            logger.info("Review пропущено: недавняя ошибка")
            return
        }

        guard let userId = currentUserIdProvider() else {
            lastSkipReason = .noCurrentUser
            logger.info("Review пропущено: нет текущего пользователя")
            return
        }
        let count = await completionsCounter.completedWorkoutCount(currentUserId: userId)

        guard let milestone = ReviewMilestone.milestone(forCompletedWorkoutCount: count) else {
            lastSkipReason = .milestoneNotReached
            logger.info("Review пропущено: веха не достигнута (тренировок: \(count))")
            return
        }

        let attempted = attemptStore.attemptedMilestones()
        guard milestone.isNotYetAttempted(in: attempted) else {
            lastSkipReason = .milestoneAlreadyAttempted
            logger.info("Review пропущено: веху \(milestone.rawValue) уже просили оценить")
            return
        }

        lastSkipReason = nil
        didRequestReviewThisSession = true
        pendingRequest = milestone
        logger.info("Review доступно: веха \(milestone.rawValue)")
    }

    func markConsumed() {
        guard let milestone = pendingRequest else { return }
        attemptStore.markAttempted(milestone)
        pendingRequest = nil
    }

    func reset() {
        pendingRequest = nil
        lastSkipReason = nil
        didRequestReviewThisSession = false
        attemptStore.reset()
    }
}
