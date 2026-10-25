import Foundation
@testable import SotkaWatch_Watch_App
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты вызова записи в HealthKit")
    @MainActor
    struct HealthKitTests {
        @Test("Должен записывать тренировку в HealthKit с датами после успешной отправки результата")
        func writesWorkoutWithDatesAfterSuccessfulSave() async throws {
            let connectivityService = MockWatchConnectivityService()
            let healthKit = HealthKitWorkoutWritingMock()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                healthKitWriting: healthKit
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

            let startDate = Date(timeIntervalSince1970: 1_700_000_000)
            let endDate = startDate.addingTimeInterval(1_800)
            viewModel.handleWorkoutResult(
                WorkoutResult(
                    count: 4,
                    duration: 1_800,
                    startDate: startDate,
                    endDate: endDate
                )
            )

            await viewModel.saveTrainingAsPassed()

            let saved = try #require(healthKit.savedWorkouts.first)
            #expect(healthKit.savedWorkouts.count == 1)
            #expect(saved.startDate == startDate)
            #expect(saved.endDate == endDate)
        }

        @Test("Не должен записывать прерванную тренировку в HealthKit")
        func skipsHealthKitWriteForInterruptedWorkout() async {
            let connectivityService = MockWatchConnectivityService()
            let healthKit = HealthKitWorkoutWritingMock()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                healthKitWriting: healthKit
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

            let startDate = Date(timeIntervalSince1970: 1_700_000_000)
            viewModel.handleWorkoutResult(
                WorkoutResult(
                    count: 2,
                    duration: 600,
                    startDate: startDate,
                    endDate: startDate.addingTimeInterval(600),
                    isInterrupted: true
                )
            )

            await viewModel.saveTrainingAsPassed()

            // Прерванные тренировки — только в дневник, без записи в «Здоровье»
            #expect(healthKit.savedWorkouts.isEmpty)
        }

        @Test("Не должен дублировать запись в HealthKit при повторном сохранении")
        func doesNotDuplicateHealthKitWriteOnSecondSave() async {
            let connectivityService = MockWatchConnectivityService()
            let healthKit = HealthKitWorkoutWritingMock()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                healthKitWriting: healthKit
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

            let startDate = Date(timeIntervalSince1970: 1_700_000_000)
            let endDate = startDate.addingTimeInterval(1_800)
            viewModel.handleWorkoutResult(
                WorkoutResult(
                    count: 4,
                    duration: 1_800,
                    startDate: startDate,
                    endDate: endDate
                )
            )

            // Повторное сохранение (например, правка комментария) не дублирует запись
            await viewModel.saveTrainingAsPassed()
            await viewModel.saveTrainingAsPassed()

            #expect(healthKit.savedWorkouts.count == 1)
            #expect(healthKit.savedWorkouts.first?.startDate == startDate)
        }

        @Test("Должен запрашивать разрешение на запись из отдельного метода requestHealthKitAuthorizationIfNeeded")
        func requestsWriteAuthorizationFromSeparateMethod() async {
            let connectivityService = MockWatchConnectivityService()
            let healthKit = HealthKitWorkoutWritingMock()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService,
                healthKitWriting: healthKit
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

            // loadData больше не запрашивает авторизацию HealthKit (Этап 8)
            #expect(healthKit.authorizationRequestCount == 0)

            await viewModel.requestHealthKitAuthorizationIfNeeded()

            // Новый метод запрашивает авторизацию ровно один раз
            #expect(healthKit.authorizationRequestCount == 1)
        }
    }
}
