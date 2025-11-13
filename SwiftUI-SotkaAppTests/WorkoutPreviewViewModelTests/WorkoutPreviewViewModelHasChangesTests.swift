import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для hasChanges и isPlannedCountDisabled")
    struct HasChangesTests {
        @Test("Должен возвращать true для isPlannedCountDisabled когда selectedExecutionType = turbo")
        @MainActor
        func returnsTrueForIsPlannedCountDisabledWhenTurbo() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .turbo

            #expect(viewModel.isPlannedCountDisabled)
        }

        @Test("Должен возвращать false для isPlannedCountDisabled когда selectedExecutionType = cycles")
        @MainActor
        func returnsFalseForIsPlannedCountDisabledWhenCycles() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .cycles

            #expect(!viewModel.isPlannedCountDisabled)
        }

        @Test("Должен возвращать false для isPlannedCountDisabled когда selectedExecutionType = sets")
        @MainActor
        func returnsFalseForIsPlannedCountDisabledWhenSets() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .sets

            #expect(!viewModel.isPlannedCountDisabled)
        }

        @Test("Должен возвращать false для isPlannedCountDisabled когда selectedExecutionType = nil")
        @MainActor
        func returnsFalseForIsPlannedCountDisabledWhenNil() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = nil

            #expect(!viewModel.isPlannedCountDisabled)
        }

        @Test("Должен возвращать false для hasChanges при загрузке существующей пройденной активности")
        @MainActor
        func returnsFalseForHasChangesWhenLoadingExistingPassedActivity() throws {
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

            #expect(!viewModel.hasChanges)
        }

        @Test("Должен возвращать true для hasChanges после изменения количества повторений")
        @MainActor
        func returnsTrueForHasChangesAfterChangingTrainingCount() throws {
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

            let training1 = DayActivityTraining(
                count: 5,
                typeId: ExerciseType.pullups.rawValue,
                sortOrder: 0,
                dayActivity: dayActivity
            )
            context.insert(training1)
            try context.save()

            viewModel.updateData(modelContext: context, day: 5, restTime: 60)
            let training = try #require(viewModel.trainings.first)
            viewModel.updatePlannedCount(id: training.id, action: .increment)

            #expect(viewModel.hasChanges)
        }

        @Test("Должен возвращать true для hasChanges после изменения plannedCount")
        @MainActor
        func returnsTrueForHasChangesAfterChangingPlannedCount() throws {
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
            viewModel.updatePlannedCount(id: "plannedCount", action: .increment)

            #expect(viewModel.hasChanges)
        }

        @Test("Должен возвращать true для hasChanges после изменения типа выполнения")
        @MainActor
        func returnsTrueForHasChangesAfterChangingExecutionType() throws {
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
                day: 50,
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

            viewModel.updateData(modelContext: context, day: 50, restTime: 60)
            viewModel.updateExecutionType(.sets)

            #expect(viewModel.hasChanges)
        }

        @Test("Должен возвращать true для hasChanges после изменения комментария")
        @MainActor
        func returnsTrueForHasChangesAfterChangingComment() throws {
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
            dayActivity.comment = "Original comment"
            context.insert(dayActivity)
            try context.save()

            viewModel.updateData(modelContext: context, day: 5, restTime: 60)
            viewModel.updateComment("New comment")

            #expect(viewModel.hasChanges)
        }

        @Test("Должен возвращать false для hasChanges после возврата всех значений к исходным")
        @MainActor
        func returnsFalseForHasChangesAfterRevertingAllValuesToOriginal() throws {
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
            dayActivity.comment = "Original comment"
            context.insert(dayActivity)
            try context.save()

            viewModel.updateData(modelContext: context, day: 5, restTime: 60)
            viewModel.updatePlannedCount(id: "plannedCount", action: .increment)
            #expect(viewModel.hasChanges)

            viewModel.updatePlannedCount(id: "plannedCount", action: .decrement)
            #expect(!viewModel.hasChanges)
        }

        @Test("Должен возвращать false для hasChanges при загрузке новой активности")
        @MainActor
        func returnsFalseForHasChangesWhenLoadingNewActivity() throws {
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

            #expect(!viewModel.hasChanges)
        }
    }
}
