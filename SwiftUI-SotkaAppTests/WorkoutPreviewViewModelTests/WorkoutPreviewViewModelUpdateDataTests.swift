import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для updateData")
    struct UpdateDataTests {
        @Test("Должен загружать существующую активность из базы данных в простые модели")
        @MainActor
        func loadsExistingActivityFromDatabase() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            let dayActivity = DayActivity(
                day: 5,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 10,
                plannedCount: 8,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                createDate: Date(),
                modifyDate: Date(),
                user: user
            )
            dayActivity.comment = "Test comment"
            context.insert(dayActivity)

            let training1 = DayActivityTraining(
                count: 5,
                typeId: ExerciseType.pullups.rawValue,
                sortOrder: 0,
                dayActivity: dayActivity
            )
            let training2 = DayActivityTraining(
                count: 10,
                typeId: ExerciseType.pushups.rawValue,
                sortOrder: 1,
                dayActivity: dayActivity
            )
            context.insert(training1)
            context.insert(training2)
            try context.save()

            viewModel.updateData(modelContext: context, day: 5, restTime: 60)

            #expect(viewModel.dayNumber == 5)
            let count = try #require(viewModel.count)
            #expect(count == 10)
            let plannedCount = try #require(viewModel.plannedCount)
            #expect(plannedCount == 8)
            let comment = try #require(viewModel.comment)
            #expect(comment == "Test comment")
            #expect(viewModel.trainings.count == 2)
        }

        @Test("Должен инициализировать пустые значения если активность не существует")
        @MainActor
        func initializesEmptyValuesIfActivityDoesNotExist() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            viewModel.updateData(modelContext: context, day: 1, restTime: 60)

            #expect(viewModel.dayNumber == 1)
            #expect(viewModel.count == nil)
            #expect(viewModel.comment == nil)
            #expect(!viewModel.trainings.isEmpty)
        }

        @Test("Должен игнорировать активность с типом отличным от workout")
        @MainActor
        func ignoresActivityWithNonWorkoutType() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let dayActivity = DayActivity(
                day: 1,
                activityTypeRaw: DayActivityType.rest.rawValue,
                createDate: Date(),
                modifyDate: Date(),
                user: user
            )
            context.insert(dayActivity)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            viewModel.updateData(modelContext: context, day: 1, restTime: 60)

            #expect(viewModel.dayNumber == 1)
            #expect(viewModel.count == nil)
            #expect(!viewModel.trainings.isEmpty)
        }

        @Test("Должен определять доступные типы выполнения для дня 50-91")
        @MainActor
        func determinesAvailableExecutionTypesForDays50To91() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            viewModel.updateData(modelContext: context, day: 50, restTime: 60)

            #expect(viewModel.availableExecutionTypes.count == 2)
            #expect(viewModel.availableExecutionTypes.contains(.cycles))
            #expect(viewModel.availableExecutionTypes.contains(.sets))
        }

        @Test("Должен определять доступные типы выполнения для дня 92-98")
        @MainActor
        func determinesAvailableExecutionTypesForDays92To98() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            viewModel.updateData(modelContext: context, day: 92, restTime: 60)

            #expect(viewModel.availableExecutionTypes.count == 3)
            #expect(viewModel.availableExecutionTypes.contains(.cycles))
            #expect(viewModel.availableExecutionTypes.contains(.sets))
            #expect(viewModel.availableExecutionTypes.contains(.turbo))
        }

        @Test("Должен устанавливать тип выполнения по умолчанию для дня 50")
        @MainActor
        func setsDefaultExecutionTypeForDay50() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            viewModel.updateData(modelContext: context, day: 50, restTime: 60)

            let executionType = try #require(viewModel.selectedExecutionType)
            #expect(executionType == .cycles)
        }

        @Test("Должен устанавливать тип выполнения по умолчанию для дня 92")
        @MainActor
        func setsDefaultExecutionTypeForDay92() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            viewModel.updateData(modelContext: context, day: 92, restTime: 60)

            let executionType = try #require(viewModel.selectedExecutionType)
            #expect(executionType == .turbo)
        }

        @Test("Должен устанавливать wasOriginallyPassed в true для существующей тренировки")
        @MainActor
        func setsWasOriginallyPassedToTrueForExistingTraining() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            let dayActivity = DayActivity(
                day: 5,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 10,
                plannedCount: 8,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                createDate: Date(),
                modifyDate: Date(),
                user: user
            )
            context.insert(dayActivity)
            try context.save()

            viewModel.updateData(modelContext: context, day: 5, restTime: 60)

            #expect(viewModel.wasOriginallyPassed)
        }

        @Test("Должен устанавливать wasOriginallyPassed в false для новой тренировки")
        @MainActor
        func setsWasOriginallyPassedToFalseForNewTraining() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            viewModel.updateData(modelContext: context, day: 1, restTime: 60)

            #expect(!viewModel.wasOriginallyPassed)
        }

        @Test("Должен сохранять count неизменным при смене типа для новой тренировки")
        @MainActor
        func preservesCountWhenChangingTypeForNewTraining() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            viewModel.updateData(modelContext: context, day: 1, restTime: 60)
            #expect(viewModel.count == nil)

            viewModel.updateExecutionType(.sets)

            #expect(viewModel.count == nil)
        }

        @Test("Должен сохранять count неизменным при смене типа для существующей тренировки")
        @MainActor
        func preservesCountWhenChangingTypeForExistingTraining() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            let dayActivity = DayActivity(
                day: 5,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 5,
                plannedCount: 8,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                createDate: Date(),
                modifyDate: Date(),
                user: user
            )
            context.insert(dayActivity)
            try context.save()

            viewModel.updateData(modelContext: context, day: 5, restTime: 60)
            let initialCount = try #require(viewModel.count)
            #expect(initialCount == 5)

            viewModel.updateExecutionType(.sets)

            let count = try #require(viewModel.count)
            #expect(count == 5)
        }

        @Test("Должен преобразовывать DayActivityTraining в WorkoutPreviewTraining")
        @MainActor
        func convertsDayActivityTrainingToWorkoutPreviewTraining() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            let fetchedUser = try #require(context.fetch(FetchDescriptor<User>()).first)
            let dayActivity = DayActivity(
                day: 1,
                activityTypeRaw: DayActivityType.workout.rawValue,
                createDate: Date(),
                modifyDate: Date(),
                user: fetchedUser
            )
            context.insert(dayActivity)

            let training = DayActivityTraining(
                count: 15,
                typeId: ExerciseType.squats.rawValue,
                customTypeId: "custom-123",
                sortOrder: 2,
                dayActivity: dayActivity
            )
            context.insert(training)
            try context.save()

            viewModel.updateData(modelContext: context, day: 1, restTime: 60)

            #expect(viewModel.trainings.count == 1)
            let previewTraining = try #require(viewModel.trainings.first)
            let count = try #require(previewTraining.count)
            #expect(count == 15)
            let typeId = try #require(previewTraining.typeId)
            #expect(typeId == ExerciseType.squats.rawValue)
            let customTypeId = try #require(previewTraining.customTypeId)
            #expect(customTypeId == "custom-123")
            let sortOrder = try #require(previewTraining.sortOrder)
            #expect(sortOrder == 2)
        }

        @Test("Должен обновлять данные если dayNumber не совпадает с day")
        @MainActor
        func updatesDataIfDayNumberDoesNotMatch() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = 5
            viewModel.trainings = [
                WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]

            viewModel.updateData(modelContext: context, day: 10, restTime: 60)

            #expect(viewModel.dayNumber == 10)
        }

        @Test("Должен обновлять данные если trainings пустой")
        @MainActor
        func updatesDataIfTrainingsIsEmpty() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = 5
            viewModel.trainings = []

            viewModel.updateData(modelContext: context, day: 5, restTime: 60)

            #expect(!viewModel.trainings.isEmpty)
        }

        @Test("Не должен обновлять данные если dayNumber совпадает и trainings не пустой")
        @MainActor
        func doesNotUpdateDataIfDayNumberMatchesAndTrainingsNotEmpty() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()
            viewModel.updateData(modelContext: context, day: 5, restTime: 60)
            let initialTrainings = viewModel.trainings
            let initialDayNumber = viewModel.dayNumber
            let initialCount = viewModel.count
            let initialComment = viewModel.comment

            viewModel.updateData(modelContext: context, day: 5, restTime: 60)

            #expect(viewModel.dayNumber == initialDayNumber)
            #expect(viewModel.trainings == initialTrainings)
            #expect(viewModel.count == initialCount)
            #expect(viewModel.comment == initialComment)
        }
    }
}
