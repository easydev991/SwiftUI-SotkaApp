import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для updateExecutionType")
    @MainActor
    struct UpdateExecutionTypeTests {
        @Test("Должен использовать метод withExecutionType для обновления")
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

            viewModel.updateData(
                modelContext: context,
                day: 50,
                restTime: 60,
                activitiesService: DailyActivitiesService(client: MockDaysClient())
            )

            viewModel.updateExecutionType(.cycles)

            let executionType = try #require(viewModel.selectedExecutionType)
            #expect(executionType == .cycles)
        }

        @Test("Должен создавать новый экземпляр WorkoutProgramCreator при изменении типа")
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
            viewModel.updateData(
                modelContext: context,
                day: 1,
                restTime: 60,
                activitiesService: DailyActivitiesService(client: MockDaysClient())
            )
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

            viewModel.updateData(
                modelContext: context,
                day: 92,
                restTime: 60,
                activitiesService: DailyActivitiesService(client: MockDaysClient())
            )
            let initialTrainings = viewModel.trainings

            viewModel.updateExecutionType(.cycles)

            let executionType = try #require(viewModel.selectedExecutionType)
            #expect(executionType == .cycles)
            // Для дня 92 при смене с turbo на cycles упражнения должны измениться
            #expect(viewModel.trainings != initialTrainings)
        }

        @Test("Должен пересчитывать количество кругов при изменении типа")
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
            viewModel.updateData(
                modelContext: context,
                day: 1,
                restTime: 60,
                activitiesService: DailyActivitiesService(client: MockDaysClient())
            )
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
            viewModel.updateData(
                modelContext: context,
                day: 50,
                restTime: 60,
                activitiesService: DailyActivitiesService(client: MockDaysClient())
            )
            viewModel.plannedCount = 10

            viewModel.updateExecutionType(.cycles)

            let preservedPlannedCount = try #require(viewModel.plannedCount)
            #expect(preservedPlannedCount == 10)
        }

        @Test("Должен сохранять count упражнений установленный пользователем при смене типа выполнения")
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
            viewModel.updateData(
                modelContext: context,
                day: 50,
                restTime: 60,
                activitiesService: DailyActivitiesService(client: MockDaysClient())
            )
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

        @Test("Должен сохранять разные значения для двух приседаний при переключении между кругами и подходами")
        func preservesDifferentSquatsCountsWhenChangingExecutionType() throws {
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
            viewModel.updateData(
                modelContext: context,
                day: 5,
                restTime: 60,
                activitiesService: DailyActivitiesService(client: MockDaysClient())
            )

            let squats = viewModel.trainings
                .sorted
                .filter { $0.typeId == ExerciseType.squats.rawValue }
            #expect(squats.count == 2)

            let firstSquats = try #require(squats.first)
            let lastSquats = try #require(squats.last)

            viewModel.trainings = viewModel.trainings.map { training in
                if training.id == firstSquats.id {
                    return training.withCount(8)
                }
                if training.id == lastSquats.id {
                    return training.withCount(5)
                }
                return training
            }

            viewModel.updateExecutionType(.sets)

            let updatedSquats = viewModel.trainings
                .sorted
                .filter { $0.typeId == ExerciseType.squats.rawValue }
            #expect(updatedSquats.count == 2)

            let firstUpdatedSquatsCount = try #require(updatedSquats.first?.count)
            let lastUpdatedSquatsCount = try #require(updatedSquats.last?.count)
            #expect(firstUpdatedSquatsCount == 8)
            #expect(lastUpdatedSquatsCount == 5)
        }

        @Test("Должен сохранять plannedCount и count упражнений при смене типа выполнения")
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
            viewModel.updateData(
                modelContext: context,
                day: 50,
                restTime: 60,
                activitiesService: DailyActivitiesService(client: MockDaysClient())
            )
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

        @Test("Должен сохранять добавленные в редакторе упражнения при переключении способа выполнения")
        func preservesEditorAddedExercisesWhenChangingExecutionType() throws {
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
            viewModel.updateData(
                modelContext: context,
                day: 5,
                restTime: 60,
                activitiesService: DailyActivitiesService(client: MockDaysClient())
            )
            let programCount = viewModel.trainings.count
            let addedCustom = WorkoutPreviewTraining(
                count: 7,
                typeId: nil,
                customTypeId: "custom-from-editor",
                sortOrder: programCount
            )
            viewModel.updateTrainings(viewModel.trainings + [addedCustom])

            viewModel.updateExecutionType(.sets)

            #expect(viewModel.trainings.count == programCount + 1)
            let customTraining = viewModel.trainings.first { $0.customTypeId == "custom-from-editor" }
            let customCount = try #require(customTraining?.count)
            #expect(customCount == 7)
        }
    }
}
