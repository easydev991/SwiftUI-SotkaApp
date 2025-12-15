import Foundation
@testable import SotkaWatch_Watch_App
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для computed properties")
    struct ComputedPropertiesTests {
        @Test("Должен возвращать true для isPlannedCountDisabled когда selectedExecutionType = turbo")
        @MainActor
        func returnsTrueForIsPlannedCountDisabledWhenTurbo() {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.selectedExecutionType = .turbo

            #expect(viewModel.isPlannedCountDisabled)
        }

        @Test("Должен возвращать false для isPlannedCountDisabled когда selectedExecutionType = cycles")
        @MainActor
        func returnsFalseForIsPlannedCountDisabledWhenCycles() {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.selectedExecutionType = .cycles

            #expect(!viewModel.isPlannedCountDisabled)
        }

        @Test("Должен возвращать count когда count установлен")
        @MainActor
        func returnsCountWhenCountIsSet() throws {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.count = 5
            viewModel.plannedCount = 3

            let displayedCount = try #require(viewModel.displayedCount)
            #expect(displayedCount == 5)
        }

        @Test("Должен возвращать plannedCount когда count == nil")
        @MainActor
        func returnsPlannedCountWhenCountIsNil() throws {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.count = nil
            viewModel.plannedCount = 4

            let displayedCount = try #require(viewModel.displayedCount)
            #expect(displayedCount == 4)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = cycles")
        @MainActor
        func returnsTrueForShouldShowEditButtonWhenCycles() {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.selectedExecutionType = .cycles

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = sets")
        @MainActor
        func returnsTrueForShouldShowEditButtonWhenSets() {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.selectedExecutionType = .sets

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать false для shouldShowEditButton когда selectedExecutionType = turbo")
        @MainActor
        func returnsFalseForShouldShowEditButtonWhenTurbo() {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.selectedExecutionType = .turbo

            #expect(!viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать false для hasChanges при первоначальной загрузке")
        @MainActor
        func returnsFalseForHasChangesOnInitialLoad() async throws {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            let workoutData = WorkoutData(
                day: 50,
                executionType: ExerciseExecutionType.cycles.rawValue,
                trainings: [
                    WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
                ],
                plannedCount: 4
            )
            connectivityService.mockWorkoutData = workoutData
            await viewModel.loadData(day: 50)

            #expect(!viewModel.hasChanges)
        }

        @Test("Должен возвращать true для hasChanges после изменения plannedCount")
        @MainActor
        func returnsTrueForHasChangesAfterChangingPlannedCount() async throws {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            let workoutData = WorkoutData(
                day: 50,
                executionType: ExerciseExecutionType.cycles.rawValue,
                trainings: [
                    WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
                ],
                plannedCount: 4
            )
            connectivityService.mockWorkoutData = workoutData
            await viewModel.loadData(day: 50)

            viewModel.plannedCount = 5

            #expect(viewModel.hasChanges)
        }

        @Test("Должен возвращать только упражнения с count > 0")
        @MainActor
        func returnsOnlyTrainingsWithCountGreaterThanZero() {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 3, typeId: ExerciseType.pushups.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 0, typeId: ExerciseType.squats.rawValue, sortOrder: 2),
                WorkoutPreviewTraining(count: nil, typeId: ExerciseType.austrPullups.rawValue, sortOrder: 3)
            ]

            let visibleTrainings = viewModel.visibleTrainings

            #expect(visibleTrainings.count == 2)
            #expect(visibleTrainings[0].count == 5)
            #expect(visibleTrainings[1].count == 3)
        }

        @Test("Должен возвращать пустой список если все упражнения имеют count == 0 или nil")
        @MainActor
        func returnsEmptyListWhenAllTrainingsHaveZeroOrNilCount() {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.trainings = [
                WorkoutPreviewTraining(count: 0, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: nil, typeId: ExerciseType.pushups.rawValue, sortOrder: 1)
            ]

            let visibleTrainings = viewModel.visibleTrainings

            #expect(visibleTrainings.isEmpty)
        }

        @Test("Должен возвращать все упражнения если все имеют count > 0")
        @MainActor
        func returnsAllTrainingsWhenAllHaveCountGreaterThanZero() {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 3, typeId: ExerciseType.pushups.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 10, typeId: ExerciseType.squats.rawValue, sortOrder: 2)
            ]

            let visibleTrainings = viewModel.visibleTrainings

            #expect(visibleTrainings.count == 3)
        }

        @Test("Должен возвращать пустой список если trainings пуст")
        @MainActor
        func returnsEmptyListWhenTrainingsIsEmpty() {
            let connectivityService = MockWatchConnectivityService()
            let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                appGroupHelper: appGroupHelper
            )

            viewModel.trainings = []

            let visibleTrainings = viewModel.visibleTrainings

            #expect(visibleTrainings.isEmpty)
        }
    }
}
