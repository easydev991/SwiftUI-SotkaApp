import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension DailyActivitiesServiceTests {
    @MainActor
    struct GetLastPassedNonTurboWorkoutTests {
        private func createService() -> DailyActivitiesService {
            DailyActivitiesService(client: MockDaysClient())
        }

        private func createContainer() throws -> ModelContainer {
            try ModelContainer(
                for: DayActivity.self, User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        private func createUser(id: Int, context: ModelContext) -> User {
            let user = User(id: id, userName: "user\(id)", fullName: "User \(id)", email: "user\(id)@test.com")
            context.insert(user)
            return user
        }

        @discardableResult
        private func createDayActivity(
            day: Int,
            activityType: DayActivityType,
            count: Int?,
            plannedCount: Int? = nil,
            executionType: ExerciseExecutionType? = nil,
            shouldDelete: Bool = false,
            createDate: Date = .now,
            modifyDate: Date = .now,
            user: User?,
            context: ModelContext
        ) -> DayActivity {
            let activity = DayActivity(
                day: day,
                activityTypeRaw: activityType.rawValue,
                count: count,
                plannedCount: plannedCount,
                executeTypeRaw: executionType?.rawValue,
                createDate: createDate,
                modifyDate: modifyDate,
                user: user
            )
            activity.shouldDelete = shouldDelete
            context.insert(activity)
            return activity
        }

        @Test("Возвращает nil когда нет активностей")
        func getLastPassedNonTurboWorkoutActivity_WhenNoActivities_ReturnsNil() throws {
            let container = try createContainer()
            let context = container.mainContext

            _ = createUser(id: 1, context: context)
            try context.save()

            let result = createService().getLastPassedNonTurboWorkoutActivity(context: context)

            #expect(result == nil)
        }

        @Test("Возвращает nil когда нет пройденных активностей (count = nil)")
        func getLastPassedNonTurboWorkoutActivity_WhenNoPassedActivities_ReturnsNil() throws {
            let container = try createContainer()
            let context = container.mainContext

            let user = createUser(id: 1, context: context)
            createDayActivity(day: 5, activityType: .workout, count: nil, user: user, context: context)
            createDayActivity(day: 10, activityType: .workout, count: nil, user: user, context: context)
            try context.save()

            let result = createService().getLastPassedNonTurboWorkoutActivity(context: context)

            #expect(result == nil)
        }

        @Test("Возвращает единственную пройденную активность")
        func getLastPassedNonTurboWorkoutActivity_WhenOnePassedActivity_ReturnsIt() throws {
            let container = try createContainer()
            let context = container.mainContext

            let user = createUser(id: 1, context: context)
            createDayActivity(day: 5, activityType: .workout, count: 3, user: user, context: context)
            try context.save()

            let result = createService().getLastPassedNonTurboWorkoutActivity(context: context)

            let activity = try #require(result)
            #expect(activity.day == 5)
            #expect(activity.count == 3)
        }

        @Test("Возвращает самую недавнюю по дате изменения (не по номеру дня)")
        func getLastPassedNonTurboWorkoutActivity_ReturnsLatestByModifyDate() throws {
            let container = try createContainer()
            let context = container.mainContext

            let user = createUser(id: 1, context: context)
            // День 3 изменён раньше, но день 5 изменён позже - должен вернуться день 5
            createDayActivity(
                day: 3,
                activityType: .workout,
                count: 2,
                modifyDate: Date.now.addingTimeInterval(-3600), // час назад
                user: user,
                context: context
            )
            createDayActivity(
                day: 5,
                activityType: .workout,
                count: 4,
                modifyDate: .now, // сейчас
                user: user,
                context: context
            )
            // День 7 изменён ещё раньше - не должен вернуться
            createDayActivity(
                day: 7,
                activityType: .workout,
                count: 5,
                modifyDate: Date.now.addingTimeInterval(-7200), // 2 часа назад
                user: user,
                context: context
            )
            try context.save()

            let result = createService().getLastPassedNonTurboWorkoutActivity(context: context)

            let activity = try #require(result)
            #expect(activity.day == 5) // Самый недавний по modifyDate, а не максимальный день
            #expect(activity.count == 4)
        }

        @Test("Игнорирует активности не типа workout")
        func getLastPassedNonTurboWorkoutActivity_IgnoresNonWorkoutActivities() throws {
            let container = try createContainer()
            let context = container.mainContext

            let user = createUser(id: 1, context: context)
            createDayActivity(day: 5, activityType: .workout, count: 3, user: user, context: context)
            createDayActivity(day: 10, activityType: .stretch, count: 5, user: user, context: context)
            createDayActivity(day: 12, activityType: .rest, count: 1, user: user, context: context)
            try context.save()

            let result = createService().getLastPassedNonTurboWorkoutActivity(context: context)

            let activity = try #require(result)
            #expect(activity.day == 5)
            #expect(activity.count == 3)
        }

        @Test("Игнорирует активности помеченные на удаление")
        func getLastPassedNonTurboWorkoutActivity_IgnoresDeletedActivities() throws {
            let container = try createContainer()
            let context = container.mainContext

            let user = createUser(id: 1, context: context)
            createDayActivity(day: 5, activityType: .workout, count: 3, shouldDelete: true, user: user, context: context)
            createDayActivity(day: 3, activityType: .workout, count: 2, user: user, context: context)
            try context.save()

            let result = createService().getLastPassedNonTurboWorkoutActivity(context: context)

            let activity = try #require(result)
            #expect(activity.day == 3)
            #expect(activity.count == 2)
        }

        @Test("Возвращает только активности текущего пользователя")
        func getLastPassedNonTurboWorkoutActivity_ReturnsOnlyCurrentUserActivities() throws {
            let container = try createContainer()
            let context = container.mainContext

            let user2 = createUser(id: 2, context: context)
            let user1 = createUser(id: 1, context: context)
            try context.save()

            createDayActivity(day: 5, activityType: .workout, count: 7, user: user2, context: context)
            createDayActivity(day: 3, activityType: .workout, count: 4, user: user1, context: context)
            try context.save()

            let result = createService().getLastPassedNonTurboWorkoutActivity(context: context)

            let activity = try #require(result)
            #expect(activity.day == 3)
            #expect(activity.count == 4)
            #expect(activity.user?.id == 1)
        }

        @Test("Игнорирует turbo-тренировки")
        func getLastPassedNonTurboWorkoutActivity_IgnoresTurboWorkouts() throws {
            let container = try createContainer()
            let context = container.mainContext

            let user = createUser(id: 1, context: context)
            // Обычная тренировка изменена раньше
            createDayActivity(
                day: 5,
                activityType: .workout,
                count: 3,
                executionType: .cycles,
                modifyDate: Date.now.addingTimeInterval(-3600),
                user: user,
                context: context
            )
            // Turbo тренировка изменена позже (более недавняя), но должна игнорироваться
            createDayActivity(
                day: 7,
                activityType: .workout,
                count: 5,
                executionType: .turbo,
                modifyDate: .now,
                user: user,
                context: context
            )
            try context.save()

            let result = createService().getLastPassedNonTurboWorkoutActivity(context: context)

            let activity = try #require(result)
            #expect(activity.day == 5) // Turbo тренировка игнорируется
            #expect(activity.count == 3)
        }

        @Test("Возвращает nil если есть только turbo-тренировки")
        func getLastPassedNonTurboWorkoutActivity_WhenOnlyTurboWorkouts_ReturnsNil() throws {
            let container = try createContainer()
            let context = container.mainContext

            let user = createUser(id: 1, context: context)
            createDayActivity(day: 5, activityType: .workout, count: 3, executionType: .turbo, user: user, context: context)
            createDayActivity(day: 7, activityType: .workout, count: 5, executionType: .turbo, user: user, context: context)
            try context.save()

            let result = createService().getLastPassedNonTurboWorkoutActivity(context: context)

            #expect(result == nil)
        }

        @Test("Возвращает активность обновлённую позже (modifyDate), даже если создана раньше")
        func getLastPassedNonTurboWorkoutActivity_ReturnsByModifyDate_NotCreateDate() throws {
            let container = try createContainer()
            let context = container.mainContext

            let user = createUser(id: 1, context: context)
            // День 19: создан давно, изменён давно
            createDayActivity(
                day: 19,
                activityType: .workout,
                count: 8,
                createDate: Date.now.addingTimeInterval(-86400 * 7), // создан неделю назад
                modifyDate: Date.now.addingTimeInterval(-86400 * 5), // изменён 5 дней назад
                user: user,
                context: context
            )
            // День 24: создан недавно, изменён сейчас (симуляция сохранения результатов)
            createDayActivity(
                day: 24,
                activityType: .workout,
                count: 8,
                createDate: Date.now.addingTimeInterval(-86400 * 3), // создан 3 дня назад
                modifyDate: .now, // изменён сейчас - должен вернуться
                user: user,
                context: context
            )
            try context.save()

            let result = createService().getLastPassedNonTurboWorkoutActivity(context: context)

            let activity = try #require(result)
            #expect(activity.day == 24) // День 24 изменён позже, чем день 19
            #expect(activity.count == 8)
        }
    }
}
