import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutPreviewViewModelTests {
    // MARK: - updateExecutionType Tests

    @Test("Должен использовать метод withExecutionType для обновления")
    @MainActor
    func usesWithExecutionTypeMethodForUpdate() throws {
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

        viewModel.updateExecutionType(.cycles)

        let executionType = try #require(viewModel.selectedExecutionType)
        #expect(executionType == .cycles)
    }

    @Test("Должен создавать новый экземпляр WorkoutProgramCreator при изменении типа")
    @MainActor
    func createsNewWorkoutProgramCreatorInstanceWhenChangingType() throws {
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

        // Используем день 1, где для cycles = 4, для sets = 6
        viewModel.updateData(modelContext: context, day: 1, restTime: 60)
        let initialPlannedCount = try #require(viewModel.plannedCount)
        // Для дня 1 дефолтный тип - cycles (4 круга)
        #expect(initialPlannedCount == 4)

        viewModel.updateExecutionType(.sets)

        // Для дня 1 при смене на sets должно быть 6 кругов
        let newPlannedCount = try #require(viewModel.plannedCount)
        #expect(newPlannedCount == 6)
        #expect(newPlannedCount != initialPlannedCount)
    }

    @Test("Должен обновлять упражнения при изменении типа выполнения")
    @MainActor
    func updatesExercisesWhenChangingExecutionType() throws {
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
        let initialTrainings = viewModel.trainings

        viewModel.updateExecutionType(.cycles)

        let executionType = try #require(viewModel.selectedExecutionType)
        #expect(executionType == .cycles)
        // Для дня 92 при смене с turbo на cycles упражнения должны измениться
        #expect(viewModel.trainings != initialTrainings)
    }

    @Test("Должен пересчитывать количество кругов при изменении типа")
    @MainActor
    func recalculatesCircleCountWhenChangingType() throws {
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

        // Используем день 1, где для cycles = 4, для sets = 6
        viewModel.updateData(modelContext: context, day: 1, restTime: 60)
        let initialPlannedCount = try #require(viewModel.plannedCount)
        // Для дня 1 дефолтный тип - cycles (4 круга)
        #expect(initialPlannedCount == 4)

        viewModel.updateExecutionType(.sets)

        let plannedCount = try #require(viewModel.plannedCount)
        // Для дня 1 с sets должно быть 6 кругов
        #expect(plannedCount == 6)
        #expect(plannedCount != initialPlannedCount)
    }

    @Test("Должен сохранять plannedCount установленный пользователем при смене типа выполнения")
    @MainActor
    func preservesUserSetPlannedCountWhenChangingExecutionType() throws {
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
        viewModel.plannedCount = 10

        viewModel.updateExecutionType(.cycles)

        let preservedPlannedCount = try #require(viewModel.plannedCount)
        #expect(preservedPlannedCount == 10)
    }

    @Test("Должен сохранять count упражнений установленный пользователем при смене типа выполнения")
    @MainActor
    func preservesUserSetTrainingCountWhenChangingExecutionType() throws {
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
        let initialPullupsTraining = viewModel.trainings.first { training in
            training.typeId == ExerciseType.pullups.rawValue
        }
        guard let initialPullupsTraining else {
            return
        }
        let updatedPullupsTraining = initialPullupsTraining.withCount(7)
        viewModel.trainings = viewModel.trainings.map { training in
            if training.id == updatedPullupsTraining.id {
                return updatedPullupsTraining
            }
            return training
        }

        viewModel.updateExecutionType(.cycles)

        let preservedPullupsTraining = viewModel.trainings.first { training in
            training.typeId == ExerciseType.pullups.rawValue
        }
        let preservedCount = try #require(preservedPullupsTraining?.count)
        #expect(preservedCount == 7)
    }

    @Test("Должен сохранять plannedCount и count упражнений при смене типа выполнения")
    @MainActor
    func preservesPlannedCountAndTrainingCountWhenChangingExecutionType() throws {
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
        viewModel.plannedCount = 10

        let initialPullupsTraining = viewModel.trainings.first { training in
            training.typeId == ExerciseType.pullups.rawValue
        }
        guard let initialPullupsTraining else {
            return
        }
        let updatedPullupsTraining = initialPullupsTraining.withCount(7)
        viewModel.trainings = viewModel.trainings.map { training in
            if training.id == updatedPullupsTraining.id {
                return updatedPullupsTraining
            }
            return training
        }

        let initialPushupsTraining = viewModel.trainings.first { training in
            training.typeId == ExerciseType.pushups.rawValue
        }
        guard let initialPushupsTraining else {
            return
        }
        let updatedPushupsTraining = initialPushupsTraining.withCount(5)
        viewModel.trainings = viewModel.trainings.map { training in
            if training.id == updatedPushupsTraining.id {
                return updatedPushupsTraining
            }
            return training
        }

        viewModel.updateExecutionType(.cycles)

        let preservedPlannedCount = try #require(viewModel.plannedCount)
        #expect(preservedPlannedCount == 10)

        let preservedPullupsTraining = viewModel.trainings.first { training in
            training.typeId == ExerciseType.pullups.rawValue
        }
        let preservedPullupsCount = try #require(preservedPullupsTraining?.count)
        #expect(preservedPullupsCount == 7)

        let preservedPushupsTraining = viewModel.trainings.first { training in
            training.typeId == ExerciseType.pushups.rawValue
        }
        let preservedPushupsCount = try #require(preservedPushupsTraining?.count)
        #expect(preservedPushupsCount == 5)
    }
}
