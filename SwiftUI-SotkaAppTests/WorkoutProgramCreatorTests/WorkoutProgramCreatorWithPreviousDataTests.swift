import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutProgramCreatorTests {
    // MARK: - withData(from:) Tests

    @Suite("Тесты для withData(from:)")
    @MainActor
    struct WorkoutProgramCreatorWithPreviousDataTests {
        private func createContainer() throws -> ModelContainer {
            try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        private func createUser(id: Int, context: ModelContext) -> User {
            let user = User(id: id, userName: "user\(id)", fullName: "User \(id)", email: "user\(id)@test.com")
            context.insert(user)
            return user
        }

        @discardableResult
        private func createPreviousActivity(
            day: Int,
            count: Int?,
            plannedCount: Int?,
            executionType: ExerciseExecutionType?,
            trainings: [DayActivityTraining] = [],
            user: User?,
            context: ModelContext
        ) -> DayActivity {
            let activity = DayActivity(
                day: day,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: count,
                plannedCount: plannedCount,
                executeTypeRaw: executionType?.rawValue,
                trainingTypeRaw: nil,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            for training in trainings {
                training.dayActivity = activity
                activity.trainings.append(training)
            }
            context.insert(activity)
            return activity
        }

        @Test("Подставляет plannedCount из count предыдущей тренировки")
        func withData_UsesCountFromPreviousActivity() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creator = WorkoutProgramCreator(day: 10)
            createPreviousActivity(
                day: 5,
                count: 8,
                plannedCount: 6,
                executionType: .cycles,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            let plannedCount = try #require(updatedCreator.plannedCount)
            #expect(plannedCount == 8)
        }

        @Test("Подставляет plannedCount из plannedCount предыдущей тренировки если count nil")
        func withData_UsesPlannedCountWhenCountIsNil() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creator = WorkoutProgramCreator(day: 10)
            createPreviousActivity(
                day: 5,
                count: nil,
                plannedCount: 7,
                executionType: .cycles,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            let plannedCount = try #require(updatedCreator.plannedCount)
            #expect(plannedCount == 7)
        }

        @Test("Сохраняет дефолтный plannedCount если в предыдущей тренировке нет значений")
        func withData_KeepsDefaultWhenNoValuesInPrevious() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creator = WorkoutProgramCreator(day: 10)
            let defaultPlannedCount = try #require(creator.plannedCount)
            createPreviousActivity(
                day: 5,
                count: nil,
                plannedCount: nil,
                executionType: .cycles,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            let plannedCount = try #require(updatedCreator.plannedCount)
            #expect(plannedCount == defaultPlannedCount)
        }

        @Test("Подставляет executionType из предыдущей тренировки")
        func withData_UsesExecutionTypeFromPreviousActivity() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creator = WorkoutProgramCreator(day: 10)
            createPreviousActivity(
                day: 5,
                count: 8,
                plannedCount: 6,
                executionType: .sets,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            #expect(updatedCreator.executionType == .sets)
        }

        @Test("Сохраняет дефолтный executionType если в предыдущей тренировке nil")
        func withData_KeepsDefaultExecutionTypeWhenNil() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creator = WorkoutProgramCreator(day: 10)
            createPreviousActivity(
                day: 5,
                count: 8,
                plannedCount: 6,
                executionType: nil,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            #expect(updatedCreator.executionType == .cycles)
        }

        @Test("Подставляет разные count для двух упражнений одного типа из предыдущей тренировки")
        func withData_PreservesDifferentCountsForDuplicateExerciseTypes() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creator = WorkoutProgramCreator(day: 10)

            let previousTrainings = [
                DayActivityTraining(count: 4, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                DayActivityTraining(count: 8, typeId: ExerciseType.squats.rawValue, sortOrder: 1),
                DayActivityTraining(count: 6, typeId: ExerciseType.pushups.rawValue, sortOrder: 2),
                DayActivityTraining(count: 5, typeId: ExerciseType.squats.rawValue, sortOrder: 3)
            ]
            createPreviousActivity(
                day: 5,
                count: 8,
                plannedCount: 6,
                executionType: .cycles,
                trainings: previousTrainings,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            let squats = updatedCreator.trainings
                .sorted
                .filter { $0.typeId == ExerciseType.squats.rawValue }
            #expect(squats.count == 2)
            let firstSquatsCount = try #require(squats.first?.count)
            let lastSquatsCount = try #require(squats.last?.count)
            #expect(firstSquatsCount == 8)
            #expect(lastSquatsCount == 5)
        }

        @Test("Подставляет повторы для каждого упражнения")
        func withData_UsesCountsForExercises() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creator = WorkoutProgramCreator(day: 10)

            let previousTrainings = [
                DayActivityTraining(count: 10, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                DayActivityTraining(count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: 1),
                DayActivityTraining(count: 12, typeId: ExerciseType.pushups.rawValue, sortOrder: 2)
            ]
            createPreviousActivity(
                day: 5,
                count: 8,
                plannedCount: 6,
                executionType: .cycles,
                trainings: previousTrainings,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            let pullups = updatedCreator.trainings.first { $0.typeId == ExerciseType.pullups.rawValue }
            let squats = updatedCreator.trainings.first { $0.typeId == ExerciseType.squats.rawValue }
            let pushups = updatedCreator.trainings.first { $0.typeId == ExerciseType.pushups.rawValue }

            #expect(pullups?.count == 10)
            #expect(squats?.count == 15)
            #expect(pushups?.count == 12)
        }

        @Test("Использует дефолт для упражнений которых нет в предыдущей тренировке")
        func withData_UsesDefaultForMissingExercises() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creator = WorkoutProgramCreator(day: 10)
            let defaultPullups = creator.trainings.first { $0.typeId == ExerciseType.pullups.rawValue }?.count

            // Предыдущая тренировка без pullups
            let previousTrainings = [
                DayActivityTraining(count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: 0)
            ]
            createPreviousActivity(
                day: 5,
                count: 8,
                plannedCount: 6,
                executionType: .cycles,
                trainings: previousTrainings,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            let pullups = updatedCreator.trainings.first { $0.typeId == ExerciseType.pullups.rawValue }
            #expect(pullups?.count == defaultPullups)
        }

        @Test("Сопоставляет пользовательские упражнения по customTypeId")
        func withData_MatchesCustomExercisesByCustomTypeId() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creatorTrainings = [
                WorkoutPreviewTraining(count: 5, typeId: nil, customTypeId: "custom-123", sortOrder: 0)
            ]
            let creator = WorkoutProgramCreator(
                day: 10,
                executionType: .cycles,
                count: nil,
                plannedCount: nil,
                trainings: creatorTrainings,
                comment: nil
            )

            let previousTrainings = [
                DayActivityTraining(count: 20, typeId: nil, customTypeId: "custom-123", sortOrder: 0)
            ]
            createPreviousActivity(
                day: 5,
                count: 8,
                plannedCount: 6,
                executionType: .cycles,
                trainings: previousTrainings,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            let customExercise = updatedCreator.trainings.first { $0.customTypeId == "custom-123" }
            #expect(customExercise?.count == 20)
        }

        @Test("Не сопоставляет стандартные упражнения с пользовательскими")
        func withData_DoesNotMatchStandardWithCustom() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creatorTrainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, customTypeId: nil, sortOrder: 0)
            ]
            let creator = WorkoutProgramCreator(
                day: 10,
                executionType: .cycles,
                count: nil,
                plannedCount: nil,
                trainings: creatorTrainings,
                comment: nil
            )

            // Предыдущая тренировка с customTypeId, но с тем же typeId
            let previousTrainings = [
                DayActivityTraining(count: 20, typeId: ExerciseType.pullups.rawValue, customTypeId: "custom-456", sortOrder: 0)
            ]
            createPreviousActivity(
                day: 5,
                count: 8,
                plannedCount: 6,
                executionType: .cycles,
                trainings: previousTrainings,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            // Должен сохранить дефолтное значение, т.к. customTypeId не совпадает
            let pullups = updatedCreator.trainings.first { $0.typeId == ExerciseType.pullups.rawValue && $0.customTypeId == nil }
            #expect(pullups?.count == 5)
        }

        @Test("Сохраняет исходные trainings если count nil в предыдущей тренировке")
        func withData_KeepsDefaultCountWhenNilInPrevious() throws {
            let container = try createContainer()
            let context = container.mainContext
            let user = createUser(id: 1, context: context)

            let creator = WorkoutProgramCreator(day: 10)
            let defaultPullups = creator.trainings.first { $0.typeId == ExerciseType.pullups.rawValue }?.count

            // Предыдущая тренировка с count=nil для упражнения
            let previousTrainings = [
                DayActivityTraining(count: nil, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]
            createPreviousActivity(
                day: 5,
                count: 8,
                plannedCount: 6,
                executionType: .cycles,
                trainings: previousTrainings,
                user: user,
                context: context
            )
            try context.save()

            let previousActivity = try #require(
                try context.fetch(FetchDescriptor<DayActivity>(predicate: #Predicate { $0.day == 5 }))
                    .first
            )
            let updatedCreator = creator.withData(from: previousActivity)

            let pullups = updatedCreator.trainings.first { $0.typeId == ExerciseType.pullups.rawValue }
            #expect(pullups?.count == defaultPullups)
        }
    }
}
