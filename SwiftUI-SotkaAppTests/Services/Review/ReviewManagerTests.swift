import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
@Suite("Тесты ReviewManager eligibility и координации")
struct ReviewManagerTests {
    private func makeSUT(
        attemptedMilestones: [ReviewMilestone] = [],
        completedWorkoutCount: Int = 0
    ) -> (ReviewManager, MockReviewAttemptStore, MockWorkoutCompletionsCounter) {
        let store = MockReviewAttemptStore(attemptedMilestones: attemptedMilestones)
        let counter = MockWorkoutCompletionsCounter(count: completedWorkoutCount)
        let manager = ReviewManager(
            attemptStore: store,
            completionsCounter: counter,
            currentUserIdProvider: { 1 }
        )
        return (manager, store, counter)
    }

    // MARK: - Eligibility: milestone reached

    @Test("Выставляет pendingRequest при достижении milestone 1")
    func setsPendingOnFirstMilestone() async throws {
        let (manager, _, _) = makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )

        let pending = try #require(manager.pendingRequest)
        #expect(pending == .first)
    }

    @Test("Выставляет pendingRequest при достижении milestone 10")
    func setsPendingOnTenthMilestone() async throws {
        let (manager, _, _) = makeSUT(completedWorkoutCount: 10)

        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )

        let pending = try #require(manager.pendingRequest)
        #expect(pending == .tenth)
    }

    @Test("Выставляет pendingRequest при достижении milestone 30")
    func setsPendingOnThirtiethMilestone() async throws {
        let (manager, _, _) = makeSUT(completedWorkoutCount: 30)

        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )

        let pending = try #require(manager.pendingRequest)
        #expect(pending == .thirtieth)
    }

    @Test("Не выставляет pendingRequest для не-milestone количества тренировок", arguments: [0, 2, 5, 9, 11, 29, 31])
    func noPendingForNonMilestone(count: Int) async {
        let (manager, _, _) = makeSUT(completedWorkoutCount: count)

        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )

        #expect(manager.pendingRequest == nil)
    }

    // MARK: - Eligibility: duplicate milestone

    @Test("Не выставляет pendingRequest если milestone уже attempted")
    func noPendingForAlreadyAttemptedMilestone() async {
        let (manager, _, _) = makeSUT(
            attemptedMilestones: [.first],
            completedWorkoutCount: 1
        )

        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )

        #expect(manager.pendingRequest == nil)
    }

    // MARK: - Eligibility: session guard

    @Test("Не выставляет pendingRequest повторно в текущей сессии")
    func noPendingTwiceInSameSession() async throws {
        let (manager, _, counter) = makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )
        let first = try #require(manager.pendingRequest)
        #expect(first == .first)

        counter.count = 10
        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )

        #expect(manager.pendingRequest == .first)
    }

    // MARK: - Eligibility: UX gates

    @Test("Не выставляет pendingRequest при hadRecentError = true")
    func noPendingWhenRecentError() async {
        let (manager, _, _) = makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: true)
        )

        #expect(manager.pendingRequest == nil)
    }

    // MARK: - Pending coordination

    @Test("markConsumed сбрасывает pendingRequest и сохраняет attempt")
    func markConsumedClearsPendingAndSavesAttempt() async throws {
        let (manager, store, _) = makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )
        let pending = try #require(manager.pendingRequest)
        #expect(pending == .first)

        manager.markConsumed()

        #expect(manager.pendingRequest == nil)
        #expect(store.savedMilestones.contains(.first))
    }

    @Test("markConsumed без pendingRequest не падает")
    func markConsumedWhenNoPendingDoesNotCrash() {
        let (manager, _, _) = makeSUT(completedWorkoutCount: 0)
        manager.markConsumed()
        #expect(manager.pendingRequest == nil)
    }

    @Test("pendingRequest выставляется только один раз за сессию даже после markConsumed")
    func pendingOnlyOncePerSessionEvenAfterConsumed() async {
        let (manager, _, counter) = makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )
        manager.markConsumed()
        #expect(manager.pendingRequest == nil)

        counter.count = 10
        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )
        #expect(manager.pendingRequest == nil)
    }

    @Test("Не зависит от факта реального показа prompt — markConsumed сохраняет attempt")
    func doesNotDependOnActualPromptDisplay() async {
        let (manager, store, _) = makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            context: ReviewContext(hadRecentError: false)
        )
        manager.markConsumed()

        #expect(store.savedMilestones.contains(.first))
    }
}

// MARK: - Mocks

private final class MockReviewAttemptStore: ReviewAttemptStoring, @unchecked Sendable {
    private var milestones: [ReviewMilestone]
    private var lastDate: Date?
    var savedMilestones: [ReviewMilestone] = []

    init(attemptedMilestones: [ReviewMilestone]) {
        self.milestones = attemptedMilestones
    }

    func attemptedMilestones() -> [ReviewMilestone] {
        milestones
    }

    func markAttempted(_ milestone: ReviewMilestone) {
        milestones.append(milestone)
        savedMilestones.append(milestone)
        lastDate = Date()
    }

    func lastReviewRequestAttemptDate() -> Date? {
        lastDate
    }
}

private final class MockWorkoutCompletionsCounter: WorkoutCompletionsCounting, @unchecked Sendable {
    var count: Int

    init(count: Int) {
        self.count = count
    }

    func completedWorkoutCount(currentUserId _: Int) async -> Int {
        count
    }
}
