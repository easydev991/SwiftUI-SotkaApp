import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты WorkoutCompletionsCounter — подсчёт завершённых тренировок")
@MainActor
struct WorkoutCompletionsCounterTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func insertActivity(
        day: Int,
        activityTypeRaw: Int?,
        count: Int?,
        shouldDelete: Bool = false,
        user: User?,
        context: ModelContext
    ) {
        let activity = DayActivity(
            day: day,
            activityTypeRaw: activityTypeRaw,
            count: count,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        activity.shouldDelete = shouldDelete
        context.insert(activity)
    }

    @Test("Возвращает 0 при отсутствии активностей")
    func returnsZeroWhenNoActivities() async throws {
        let container = try makeContainer()
        let counter = WorkoutCompletionsCounter(modelContainer: container)
        let count = await counter.completedWorkoutCount(currentUserId: 1)
        #expect(count == 0)
    }

    @Test("Считает только workout-активности с count != nil")
    func countsOnlyWorkoutsWithCount() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user = User(id: 1, genderCode: 1)
        context.insert(user)

        insertActivity(day: 1, activityTypeRaw: DayActivityType.workout.rawValue, count: 5, user: user, context: context)
        insertActivity(day: 2, activityTypeRaw: DayActivityType.workout.rawValue, count: nil, user: user, context: context)
        insertActivity(day: 3, activityTypeRaw: DayActivityType.workout.rawValue, count: 10, user: user, context: context)
        try context.save()

        let counter = WorkoutCompletionsCounter(modelContainer: container)
        let count = await counter.completedWorkoutCount(currentUserId: 1)
        #expect(count == 2)
    }

    @Test("Исключает активности с shouldDelete = true")
    func excludesShouldDelete() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user = User(id: 1, genderCode: 1)
        context.insert(user)

        insertActivity(day: 1, activityTypeRaw: DayActivityType.workout.rawValue, count: 5, user: user, context: context)
        insertActivity(
            day: 2,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 5,
            shouldDelete: true,
            user: user,
            context: context
        )
        try context.save()

        let counter = WorkoutCompletionsCounter(modelContainer: container)
        let count = await counter.completedWorkoutCount(currentUserId: 1)
        #expect(count == 1)
    }

    @Test("Исключает не-workout активности")
    func excludesNonWorkoutActivities() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user = User(id: 1, genderCode: 1)
        context.insert(user)

        insertActivity(day: 1, activityTypeRaw: DayActivityType.workout.rawValue, count: 5, user: user, context: context)
        insertActivity(day: 2, activityTypeRaw: DayActivityType.rest.rawValue, count: 5, user: user, context: context)
        insertActivity(day: 3, activityTypeRaw: DayActivityType.stretch.rawValue, count: 5, user: user, context: context)
        try context.save()

        let counter = WorkoutCompletionsCounter(modelContainer: container)
        let count = await counter.completedWorkoutCount(currentUserId: 1)
        #expect(count == 1)
    }

    @Test("Фильтрует по currentUserId")
    func filtersByUserId() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let user1 = User(id: 1, genderCode: 1)
        let user2 = User(id: 2, genderCode: 1)
        context.insert(user1)
        context.insert(user2)

        insertActivity(day: 1, activityTypeRaw: DayActivityType.workout.rawValue, count: 5, user: user1, context: context)
        insertActivity(day: 2, activityTypeRaw: DayActivityType.workout.rawValue, count: 5, user: user2, context: context)
        insertActivity(day: 3, activityTypeRaw: DayActivityType.workout.rawValue, count: 5, user: user1, context: context)
        try context.save()

        let counter = WorkoutCompletionsCounter(modelContainer: container)
        #expect(await counter.completedWorkoutCount(currentUserId: 1) == 2)
        #expect(await counter.completedWorkoutCount(currentUserId: 2) == 1)
    }

    @Test("Не считает активности без пользователя")
    func excludesActivitiesWithoutUser() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        insertActivity(day: 1, activityTypeRaw: DayActivityType.workout.rawValue, count: 5, user: nil, context: context)
        try context.save()

        let counter = WorkoutCompletionsCounter(modelContainer: container)
        let count = await counter.completedWorkoutCount(currentUserId: 1)
        #expect(count == 0)
    }
}
