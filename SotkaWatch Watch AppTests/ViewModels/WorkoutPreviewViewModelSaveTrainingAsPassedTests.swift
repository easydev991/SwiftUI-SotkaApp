import Foundation
@testable import SotkaWatch_Watch_App
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для saveTrainingAsPassed")
    struct SaveTrainingAsPassedTests {
        @Test("Должен отправлять результат тренировки через connectivityService")
        @MainActor
        func sendsWorkoutResultThroughConnectivityService() async throws {
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

            viewModel.plannedCount = 5
            await viewModel.saveTrainingAsPassed()

            let sentResult = try #require(connectivityService.sentWorkoutResult)
            #expect(sentResult.day == 50)
            #expect(sentResult.result.count == 5)
            let executionType = try #require(viewModel.selectedExecutionType)
            #expect(sentResult.executionType == executionType)
            #expect(sentResult.trainings.count == 1)
            #expect(sentResult.comment == nil)
        }

        @Test("Должен устанавливать count = plannedCount если count == nil")
        @MainActor
        func setsCountToPlannedCountWhenCountIsNil() async throws {
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

            viewModel.plannedCount = 6
            await viewModel.saveTrainingAsPassed()

            let sentResult = try #require(connectivityService.sentWorkoutResult)
            #expect(sentResult.result.count == 6)
            #expect(sentResult.trainings.count == 1)
        }

        @Test("Должен устанавливать error если selectedExecutionType == nil")
        @MainActor
        func setsErrorWhenSelectedExecutionTypeIsNil() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.selectedExecutionType = nil
            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]

            await viewModel.saveTrainingAsPassed()

            #expect(viewModel.error != nil)
            #expect(connectivityService.sentWorkoutResult == nil)
        }

        @Test("Должен устанавливать error если trainings пустой")
        @MainActor
        func setsErrorWhenTrainingsIsEmpty() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.selectedExecutionType = .cycles
            viewModel.trainings = []

            await viewModel.saveTrainingAsPassed()

            #expect(viewModel.error != nil)
            #expect(connectivityService.sentWorkoutResult == nil)
        }

        @Test("Должен не устанавливать error при сетевой ошибке отправки (error только для валидации)")
        @MainActor
        func doesNotSetErrorOnNetworkSendFailure() async throws {
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

            connectivityService.shouldSucceed = false
            connectivityService.mockError = WatchConnectivityError.sessionUnavailable

            await viewModel.saveTrainingAsPassed()

            // TrainingError используется только для валидации, не для сетевых ошибок
            #expect(viewModel.error == nil)
        }

        @Test("Должен включать workoutDuration в результат если установлен")
        @MainActor
        func includesWorkoutDurationInResultWhenSet() async throws {
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

            viewModel.workoutDuration = 180
            viewModel.plannedCount = 5
            await viewModel.saveTrainingAsPassed()

            let sentResult = try #require(connectivityService.sentWorkoutResult)
            let duration = try #require(sentResult.result.duration)
            #expect(duration == 180)
            #expect(sentResult.trainings.count == 1)
        }

        @Test("Должен передавать комментарий при сохранении тренировки")
        @MainActor
        func passesCommentWhenSavingWorkout() async throws {
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

            viewModel.comment = "Отличная тренировка!"
            viewModel.plannedCount = 5
            await viewModel.saveTrainingAsPassed()

            let sentResult = try #require(connectivityService.sentWorkoutResult)
            let comment = try #require(sentResult.comment)
            #expect(comment == "Отличная тренировка!")
            #expect(sentResult.trainings.count == 1)
        }

        @Test("Должен передавать nil для комментария если комментарий не установлен")
        @MainActor
        func passesNilForCommentWhenCommentNotSet() async throws {
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

            viewModel.comment = nil
            viewModel.plannedCount = 5
            await viewModel.saveTrainingAsPassed()

            let sentResult = try #require(connectivityService.sentWorkoutResult)
            #expect(sentResult.comment == nil)
        }

        @Test("Должен передавать nil для duration если тренировка не была пройдена")
        @MainActor
        func passesNilForDurationWhenWorkoutNotCompleted() async throws {
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

            viewModel.workoutDuration = nil
            viewModel.plannedCount = 5
            await viewModel.saveTrainingAsPassed()

            let sentResult = try #require(connectivityService.sentWorkoutResult)
            #expect(sentResult.result.duration == nil)
            #expect(sentResult.trainings.count == 1)
        }

        @Test("Должен вызывать callback onSaveCompleted после успешного сохранения")
        @MainActor
        func callsOnSaveCompletedCallbackAfterSuccessfulSave() async throws {
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

            var callbackCalled = false
            viewModel.onSaveCompleted = {
                callbackCalled = true
            }

            viewModel.plannedCount = 5
            await viewModel.saveTrainingAsPassed()

            #expect(callbackCalled)
        }

        @Test("Не должен вызывать callback onSaveCompleted при ошибке сохранения")
        @MainActor
        func doesNotCallOnSaveCompletedCallbackOnError() async throws {
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

            connectivityService.shouldSucceed = false
            connectivityService.mockError = WatchConnectivityError.sessionUnavailable

            var callbackCalled = false
            viewModel.onSaveCompleted = {
                callbackCalled = true
            }

            viewModel.plannedCount = 5
            await viewModel.saveTrainingAsPassed()

            #expect(!callbackCalled)
        }

        @Test("Должен передавать trainings при сохранении тренировки")
        @MainActor
        func passesTrainingsWhenSavingWorkout() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 1)
            ]

            let workoutData = WorkoutData(
                day: 50,
                executionType: ExerciseExecutionType.cycles.rawValue,
                trainings: trainings,
                plannedCount: 4
            )
            connectivityService.mockWorkoutData = workoutData
            await viewModel.loadData(day: 50)

            viewModel.plannedCount = 5
            await viewModel.saveTrainingAsPassed()

            let sentResult = try #require(connectivityService.sentWorkoutResult)
            let sentTrainings = try #require(sentResult.trainings)
            #expect(sentTrainings.count == 2)
            #expect(sentTrainings[0].count == 5)
            #expect(sentTrainings[0].typeId == ExerciseType.pullups.rawValue)
            #expect(sentTrainings[1].count == 10)
            #expect(sentTrainings[1].typeId == ExerciseType.pushups.rawValue)
        }
    }
}
