import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для updatePlannedCount")
    struct UpdatePlannedCountTests {
        @Test("Должен увеличивать count для упражнения при increment")
        @MainActor
        func incrementsCountForTraining() throws {
            let viewModel = WorkoutPreviewViewModel()
            let training = WorkoutPreviewTraining(
                count: 5,
                typeId: ExerciseType.pullups.rawValue,
                sortOrder: 0
            )
            viewModel.trainings = [training]

            viewModel.updatePlannedCount(id: training.id, action: .increment)

            let updatedTraining = try #require(viewModel.trainings.first)
            let updatedCount = try #require(updatedTraining.count)
            #expect(updatedCount == 6)
        }

        @Test("Должен уменьшать count для упражнения при decrement")
        @MainActor
        func decrementsCountForTraining() throws {
            let viewModel = WorkoutPreviewViewModel()
            let training = WorkoutPreviewTraining(
                count: 5,
                typeId: ExerciseType.pullups.rawValue,
                sortOrder: 0
            )
            viewModel.trainings = [training]

            viewModel.updatePlannedCount(id: training.id, action: .decrement)

            let updatedTraining = try #require(viewModel.trainings.first)
            let updatedCount = try #require(updatedTraining.count)
            #expect(updatedCount == 4)
        }

        @Test("Должен устанавливать count в 0 при decrement с count = 0")
        @MainActor
        func setsCountToZeroWhenDecrementingFromZero() throws {
            let viewModel = WorkoutPreviewViewModel()
            let training = WorkoutPreviewTraining(
                count: 0,
                typeId: ExerciseType.pullups.rawValue,
                sortOrder: 0
            )
            viewModel.trainings = [training]

            viewModel.updatePlannedCount(id: training.id, action: .decrement)

            let updatedTraining = try #require(viewModel.trainings.first)
            let updatedCount = try #require(updatedTraining.count)
            #expect(updatedCount == 0)
        }

        @Test("Должен устанавливать count в 1 при increment с count = nil")
        @MainActor
        func setsCountToOneWhenIncrementingFromNil() throws {
            let viewModel = WorkoutPreviewViewModel()
            let training = WorkoutPreviewTraining(
                count: nil,
                typeId: ExerciseType.pullups.rawValue,
                sortOrder: 0
            )
            viewModel.trainings = [training]

            viewModel.updatePlannedCount(id: training.id, action: .increment)

            let updatedTraining = try #require(viewModel.trainings.first)
            let updatedCount = try #require(updatedTraining.count)
            #expect(updatedCount == 1)
        }

        @Test("Должен находить правильное упражнение по id")
        @MainActor
        func findsCorrectTrainingById() throws {
            let viewModel = WorkoutPreviewViewModel()
            let training1 = WorkoutPreviewTraining(
                count: 5,
                typeId: ExerciseType.pullups.rawValue,
                sortOrder: 0
            )
            let training2 = WorkoutPreviewTraining(
                count: 10,
                typeId: ExerciseType.pushups.rawValue,
                sortOrder: 1
            )
            let training3 = WorkoutPreviewTraining(
                count: 15,
                typeId: ExerciseType.squats.rawValue,
                sortOrder: 2
            )
            viewModel.trainings = [training1, training2, training3]

            viewModel.updatePlannedCount(id: training2.id, action: .increment)

            let updatedTraining2 = viewModel.trainings.first { $0.id == training2.id }
            let updated = try #require(updatedTraining2)
            let updatedCount = try #require(updated.count)
            #expect(updatedCount == 11)

            let unchangedTraining1 = viewModel.trainings.first { $0.id == training1.id }
            let unchanged1 = try #require(unchangedTraining1)
            let unchangedCount1 = try #require(unchanged1.count)
            #expect(unchangedCount1 == 5)

            let unchangedTraining3 = viewModel.trainings.first { $0.id == training3.id }
            let unchanged3 = try #require(unchangedTraining3)
            let unchangedCount3 = try #require(unchanged3.count)
            #expect(unchangedCount3 == 15)
        }

        @Test("Должен увеличивать count при increment для id plannedCount когда тренировка сохранена")
        @MainActor
        func incrementsCountWhenTrainingIsSaved() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = 5
            viewModel.plannedCount = 3

            viewModel.updatePlannedCount(id: "plannedCount", action: .increment)

            let updatedCount = try #require(viewModel.count)
            #expect(updatedCount == 6)
            let plannedCount = try #require(viewModel.plannedCount)
            #expect(plannedCount == 3)
        }

        @Test("Должен уменьшать count при decrement для id plannedCount когда тренировка сохранена")
        @MainActor
        func decrementsCountWhenTrainingIsSaved() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = 5
            viewModel.plannedCount = 3

            viewModel.updatePlannedCount(id: "plannedCount", action: .decrement)

            let updatedCount = try #require(viewModel.count)
            #expect(updatedCount == 4)
            let plannedCount = try #require(viewModel.plannedCount)
            #expect(plannedCount == 3)
        }

        @Test("Должен увеличивать plannedCount при increment для id plannedCount когда тренировка не сохранена")
        @MainActor
        func incrementsPlannedCountWhenTrainingNotSaved() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = nil
            viewModel.plannedCount = 5

            viewModel.updatePlannedCount(id: "plannedCount", action: .increment)

            let updatedPlannedCount = try #require(viewModel.plannedCount)
            #expect(updatedPlannedCount == 6)
            #expect(viewModel.count == nil)
        }

        @Test("Должен уменьшать plannedCount при decrement для id plannedCount когда тренировка не сохранена")
        @MainActor
        func decrementsPlannedCountWhenTrainingNotSaved() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = nil
            viewModel.plannedCount = 5

            viewModel.updatePlannedCount(id: "plannedCount", action: .decrement)

            let updatedPlannedCount = try #require(viewModel.plannedCount)
            #expect(updatedPlannedCount == 4)
            #expect(viewModel.count == nil)
        }

        @Test("Должен устанавливать count в 0 при decrement с count = 0 для сохраненной тренировки")
        @MainActor
        func setsCountToZeroWhenDecrementingFromZeroForSavedTraining() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = 0
            viewModel.plannedCount = 3

            viewModel.updatePlannedCount(id: "plannedCount", action: .decrement)

            let updatedCount = try #require(viewModel.count)
            #expect(updatedCount == 0)
        }

        @Test("Должен устанавливать plannedCount в 0 при decrement с plannedCount = 0 для непройденной тренировки")
        @MainActor
        func setsPlannedCountToZeroWhenDecrementingFromZero() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = nil
            viewModel.plannedCount = 0

            viewModel.updatePlannedCount(id: "plannedCount", action: .decrement)

            let updatedPlannedCount = try #require(viewModel.plannedCount)
            #expect(updatedPlannedCount == 0)
        }

        @Test("Должен устанавливать plannedCount в 1 при increment с plannedCount = nil для непройденной тренировки")
        @MainActor
        func setsPlannedCountToOneWhenIncrementingFromNil() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = nil
            viewModel.plannedCount = nil

            viewModel.updatePlannedCount(id: "plannedCount", action: .increment)

            let updatedPlannedCount = try #require(viewModel.plannedCount)
            #expect(updatedPlannedCount == 1)
        }

        @Test("Должен сохранять plannedCount в buildDayActivity")
        @MainActor
        func savesPlannedCountInBuildDayActivity() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = 5
            viewModel.selectedExecutionType = .cycles
            viewModel.plannedCount = 8

            let dayActivity = viewModel.buildDayActivity()

            let savedPlannedCount = try #require(dayActivity.plannedCount)
            #expect(savedPlannedCount == 8)
        }
    }
}
