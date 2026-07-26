import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
@Suite("Тесты ReviewManager eligibility и координации")
struct ReviewManagerTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func seedActivities(count: Int, in container: ModelContainer) throws {
        let context = container.mainContext
        let user = User(id: 1, genderCode: 1)
        context.insert(user)
        for day in 1 ... count {
            let activity = DayActivity(
                day: day,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 5,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(activity)
        }
        try context.save()
    }

    private func appendActivities(additionalCount: Int, to container: ModelContainer) throws {
        let context = container.mainContext
        let user = try #require(context.fetch(FetchDescriptor<User>()).first)
        let existingCount = try context.fetchCount(FetchDescriptor<DayActivity>())
        for offset in 1 ... additionalCount {
            let activity = DayActivity(
                day: existingCount + offset,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 5,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(activity)
        }
        try context.save()
    }

    private func makeSUT(
        attemptedMilestones: [ReviewMilestone] = [],
        completedWorkoutCount: Int = 0
    ) throws -> (ReviewManager, ReviewStorage, WorkoutCompletionsCounter, ModelContainer) {
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(attemptedMilestones.map(\.rawValue), forKey: ReviewStorage.attemptedMilestones)
        let store = ReviewStorage(userDefaults: userDefaults)

        let container = try makeContainer()
        try seedActivities(count: completedWorkoutCount, in: container)
        let counter = WorkoutCompletionsCounter(modelContainer: container)

        let manager = ReviewManager(
            attemptStore: store,
            completionsCounter: counter,
            currentUserIdProvider: { 1 }
        )
        return (manager, store, counter, container)
    }

    // MARK: - Eligibility: milestone reached

    @Test("Выставляет pendingRequest при достижении milestone 1")
    func setsPendingOnFirstMilestone() async throws {
        let (manager, _, _, _) = try makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )

        let pending = try #require(manager.pendingRequest)
        #expect(pending == .first)
    }

    @Test("Выставляет pendingRequest при достижении milestone 10")
    func setsPendingOnTenthMilestone() async throws {
        let (manager, _, _, _) = try makeSUT(completedWorkoutCount: 10)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )

        let pending = try #require(manager.pendingRequest)
        #expect(pending == .tenth)
    }

    @Test("Выставляет pendingRequest при достижении milestone 30")
    func setsPendingOnThirtiethMilestone() async throws {
        let (manager, _, _, _) = try makeSUT(completedWorkoutCount: 30)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )

        let pending = try #require(manager.pendingRequest)
        #expect(pending == .thirtieth)
    }

    @Test("Не выставляет pendingRequest для count=0")
    func noPendingForZeroCount() async throws {
        let (manager, _, _, _) = try makeSUT(completedWorkoutCount: 0)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )

        #expect(manager.pendingRequest == nil)
    }

    @Test("Выставляет pendingRequest=.first для count в диапазоне 1-9")
    func pendingFirstForCount1to9() async throws {
        let (manager, _, _, _) = try makeSUT(completedWorkoutCount: 5)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )

        #expect(manager.pendingRequest == .first)
    }

    @Test("Выставляет pendingRequest=.tenth для count в диапазоне 10-29")
    func pendingTenthForCount10to29() async throws {
        let (manager, _, _, _) = try makeSUT(completedWorkoutCount: 11)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )

        #expect(manager.pendingRequest == .tenth)
    }

    // MARK: - Eligibility: duplicate milestone

    @Test("Не выставляет pendingRequest если milestone уже attempted")
    func noPendingForAlreadyAttemptedMilestone() async throws {
        let (manager, _, _, _) = try makeSUT(
            attemptedMilestones: [.first],
            completedWorkoutCount: 1
        )

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )

        #expect(manager.pendingRequest == nil)
    }

    // MARK: - Eligibility: session guard

    @Test("Не выставляет pendingRequest повторно в текущей сессии")
    func noPendingTwiceInSameSession() async throws {
        let (manager, _, _, container) = try makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )
        let first = try #require(manager.pendingRequest)
        #expect(first == .first)

        try appendActivities(additionalCount: 9, to: container)
        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )

        #expect(manager.pendingRequest == .first)
    }

    // MARK: - Eligibility: UX gates

    @Test("Не выставляет pendingRequest при hadRecentError = true")
    func noPendingWhenRecentError() async throws {
        let (manager, _, _, _) = try makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: true
        )

        #expect(manager.pendingRequest == nil)
    }

    // MARK: - Pending coordination

    @Test("markConsumed сбрасывает pendingRequest и сохраняет attempt")
    func markConsumedClearsPendingAndSavesAttempt() async throws {
        let (manager, store, _, _) = try makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )
        let pending = try #require(manager.pendingRequest)
        #expect(pending == .first)

        manager.markConsumed()

        #expect(manager.pendingRequest == nil)
        #expect(store.attemptedMilestones().contains(.first))
    }

    @Test("markConsumed без pendingRequest не падает")
    func markConsumedWhenNoPendingDoesNotCrash() throws {
        let (manager, _, _, _) = try makeSUT(completedWorkoutCount: 0)
        manager.markConsumed()
        #expect(manager.pendingRequest == nil)
    }

    @Test("pendingRequest выставляется только один раз за сессию даже после markConsumed")
    func pendingOnlyOncePerSessionEvenAfterConsumed() async throws {
        let (manager, _, _, container) = try makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )
        manager.markConsumed()
        #expect(manager.pendingRequest == nil)

        try appendActivities(additionalCount: 9, to: container)
        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )
        #expect(manager.pendingRequest == nil)
    }

    @Test("Не зависит от факта реального показа prompt — markConsumed сохраняет attempt")
    func doesNotDependOnActualPromptDisplay() async throws {
        let (manager, store, _, _) = try makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )
        manager.markConsumed()

        #expect(store.attemptedMilestones().contains(.first))
    }

    @Test("reset очищает pendingRequest и разрешает повторный review в новой сессии")
    func resetClearsStateAndAllowsNewSession() async throws {
        let (manager, store, _, container) = try makeSUT(completedWorkoutCount: 1)

        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )
        manager.markConsumed()
        #expect(manager.pendingRequest == nil)
        #expect(store.attemptedMilestones().contains(.first))

        manager.reset()
        #expect(manager.pendingRequest == nil)
        #expect(store.attemptedMilestones().isEmpty)

        try appendActivities(additionalCount: 9, to: container)
        await manager.workoutCompletedSuccessfully(
            hadRecentError: false
        )
        let pending = try #require(manager.pendingRequest)
        #expect(pending == .tenth)
    }
}
