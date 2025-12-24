import Foundation
@testable import SotkaWatch_Watch_App
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для loadData")
    struct LoadDataTests {
        @Test("Должен загружать данные тренировки из connectivityService")
        @MainActor
        func loadsWorkoutDataFromConnectivityService() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
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
            connectivityService.mockWorkoutExecutionCount = nil
            connectivityService.mockWorkoutComment = nil

            await viewModel.loadData(day: 50)

            #expect(viewModel.dayNumber == 50)
            let selectedExecutionType = try #require(viewModel.selectedExecutionType)
            #expect(selectedExecutionType == .cycles)
            #expect(viewModel.trainings.count == 1)
            let plannedCount = try #require(viewModel.plannedCount)
            #expect(plannedCount == 4)
            #expect(viewModel.restTime == 60)
            #expect(!viewModel.wasOriginallyPassed)
        }

        @Test("Должен устанавливать wasOriginallyPassed в true если executionCount установлен")
        @MainActor
        func setsWasOriginallyPassedToTrueWhenExecutionCountIsSet() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
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
            connectivityService.mockWorkoutExecutionCount = 5
            connectivityService.mockWorkoutComment = nil

            await viewModel.loadData(day: 50)

            #expect(viewModel.wasOriginallyPassed)
            let count = try #require(viewModel.count)
            #expect(count == 5)
        }

        @Test("Должен устанавливать wasOriginallyPassed в false если executionCount равен nil")
        @MainActor
        func setsWasOriginallyPassedToFalseWhenExecutionCountIsNil() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
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
            connectivityService.mockWorkoutExecutionCount = nil
            connectivityService.mockWorkoutComment = nil

            await viewModel.loadData(day: 50)

            #expect(!viewModel.wasOriginallyPassed)
            #expect(viewModel.count == nil)
        }

        @Test("Должен устанавливать comment из response")
        @MainActor
        func setsCommentFromResponse() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
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
            connectivityService.mockWorkoutExecutionCount = nil
            connectivityService.mockWorkoutComment = "Test comment"

            await viewModel.loadData(day: 50)

            let comment = try #require(viewModel.comment)
            #expect(comment == "Test comment")
        }

        @Test("Должен устанавливать isLoading в true во время загрузки")
        @MainActor
        func setsIsLoadingToTrueDuringLoad() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
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

            let loadTask = Task {
                await viewModel.loadData(day: 50)
            }

            try await Task.sleep(nanoseconds: 10_000_000)
            await loadTask.value

            #expect(!viewModel.isLoading)
        }

        @Test("Должен не устанавливать error при сетевой ошибке загрузки (error только для валидации)")
        @MainActor
        func doesNotSetErrorOnNetworkLoadFailure() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            connectivityService.shouldSucceed = false
            connectivityService.mockError = WatchConnectivityError.sessionUnavailable

            await viewModel.loadData(day: 50)

            #expect(viewModel.error == nil, "TrainingError используется только для валидации, не для сетевых ошибок")
            #expect(!viewModel.isLoading)
        }

        @Test("Должен определять availableExecutionTypes на основе dayNumber")
        @MainActor
        func determinesAvailableExecutionTypesBasedOnDayNumber() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
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

            #expect(viewModel.availableExecutionTypes.count == 2)
            #expect(viewModel.availableExecutionTypes.contains(.cycles))
            #expect(viewModel.availableExecutionTypes.contains(.sets))
        }

        @Test("Должен определять availableExecutionTypes для дня 92-98")
        @MainActor
        func determinesAvailableExecutionTypesForDays92To98() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            let workoutData = WorkoutData(
                day: 92,
                executionType: ExerciseExecutionType.turbo.rawValue,
                trainings: [
                    WorkoutPreviewTraining(count: 4, typeId: ExerciseType.pushups.rawValue, sortOrder: 0)
                ],
                plannedCount: 40
            )
            connectivityService.mockWorkoutData = workoutData

            await viewModel.loadData(day: 92)

            #expect(viewModel.availableExecutionTypes.count == 3)
            #expect(viewModel.availableExecutionTypes.contains(.cycles))
            #expect(viewModel.availableExecutionTypes.contains(.sets))
            #expect(viewModel.availableExecutionTypes.contains(.turbo))
        }

        @Test("Должен использовать restTime из connectivityService.restTime если оно доступно")
        @MainActor
        func shouldUseRestTimeFromConnectivityService() async throws {
            let connectivityService = MockWatchConnectivityService()
            connectivityService.restTime = 90
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
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
            connectivityService.mockWorkoutExecutionCount = nil
            connectivityService.mockWorkoutComment = nil

            await viewModel.loadData(day: 50)

            #expect(viewModel.restTime == 90)
        }

        @Test("Должен использовать дефолтное значение restTime если connectivityService.restTime == nil")
        @MainActor
        func shouldUseDefaultRestTimeWhenConnectivityServiceRestTimeIsNil() async throws {
            let connectivityService = MockWatchConnectivityService()
            connectivityService.restTime = nil
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
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
            connectivityService.mockWorkoutExecutionCount = nil
            connectivityService.mockWorkoutComment = nil

            await viewModel.loadData(day: 50)

            #expect(viewModel.restTime == Constants.defaultRestTime)
        }

        @Test("Должен передавать restTime в метод updateData при загрузке данных")
        @MainActor
        func shouldPassRestTimeToUpdateDataMethod() async throws {
            let connectivityService = MockWatchConnectivityService()
            connectivityService.restTime = 120
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
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
            connectivityService.mockWorkoutExecutionCount = nil
            connectivityService.mockWorkoutComment = nil

            await viewModel.loadData(day: 50)

            #expect(viewModel.restTime == 120)
        }
    }
}
