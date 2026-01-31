import Foundation
@testable import SotkaWatch_Watch_App
import Testing

struct WatchWorkoutServiceTests {
    @Test("Инициализирует тренировку из WorkoutData")
    func initializesWorkoutFromWorkoutData() {
        let trainings = [
            WorkoutPreviewTraining(
                id: "training-1",
                count: 10,
                typeId: 0,
                customTypeId: nil,
                sortOrder: 0
            )
        ]

        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: trainings,
            plannedCount: 4
        )

        let service = WatchWorkoutService(workoutData: workoutData)

        #expect(service.currentRound == 1)
        #expect(service.completedRounds == 0)
        #expect(service.workoutData.day == 5)
    }

    @Test("Отслеживает прогресс тренировки")
    func tracksWorkoutProgress() {
        let trainings = [
            WorkoutPreviewTraining(
                id: "training-1",
                count: 10,
                typeId: 0,
                customTypeId: nil,
                sortOrder: 0
            )
        ]

        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: trainings,
            plannedCount: 4
        )

        let service = WatchWorkoutService(workoutData: workoutData)

        #expect(service.currentRound == 1)
        #expect(service.completedRounds == 0)

        service.completeRound()

        #expect(service.currentRound == 2)
        #expect(service.completedRounds == 1)
    }

    @Test("Завершает круг/подход")
    func completesRound() {
        let trainings = [
            WorkoutPreviewTraining(
                id: "training-1",
                count: 10,
                typeId: 0,
                customTypeId: nil,
                sortOrder: 0
            )
        ]

        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: trainings,
            plannedCount: 4
        )

        let service = WatchWorkoutService(workoutData: workoutData)

        let initialCompletedRounds = service.completedRounds
        service.completeRound()

        #expect(service.completedRounds == initialCompletedRounds + 1)
    }

    @Test("Завершает тренировку и формирует результат")
    func finishesWorkoutAndCreatesResult() {
        let trainings = [
            WorkoutPreviewTraining(
                id: "training-1",
                count: 10,
                typeId: 0,
                customTypeId: nil,
                sortOrder: 0
            )
        ]

        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: trainings,
            plannedCount: 4
        )

        let service = WatchWorkoutService(workoutData: workoutData)

        service.completeRound()
        service.completeRound()
        service.completeRound()
        service.completeRound()

        let result = service.finishWorkout()

        #expect(result.count == 4)
    }

    @Test("Прерывает тренировку")
    func cancelsWorkout() {
        let trainings = [
            WorkoutPreviewTraining(
                id: "training-1",
                count: 10,
                typeId: 0,
                customTypeId: nil,
                sortOrder: 0
            )
        ]

        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: trainings,
            plannedCount: 4
        )

        let service = WatchWorkoutService(workoutData: workoutData)

        service.completeRound()
        service.completeRound()

        service.cancelWorkout()

        #expect(service.completedRounds == 2)
        #expect(service.isCancelled)
    }

    @Test("Формирует WorkoutResult из прогресса")
    func createsWorkoutResultFromProgress() {
        let trainings = [
            WorkoutPreviewTraining(
                id: "training-1",
                count: 10,
                typeId: 0,
                customTypeId: nil,
                sortOrder: 0
            )
        ]

        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: trainings,
            plannedCount: 4
        )

        let service = WatchWorkoutService(workoutData: workoutData)

        service.completeRound()
        service.completeRound()

        let result = service.finishWorkout()

        #expect(result.count == 2)
    }

    @Test("Обрабатывает отсутствие данных тренировки")
    func handlesMissingWorkoutData() {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: nil
        )

        let service = WatchWorkoutService(workoutData: workoutData)

        #expect(service.workoutData.trainings.isEmpty)
        #expect(service.workoutData.plannedCount == nil)
    }

    @Test("Возвращает значение по умолчанию для времени отдыха")
    func returnsDefaultRestTime() {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: nil
        )

        let service = WatchWorkoutService(workoutData: workoutData)

        #expect(service.getRestTime() == Constants.defaultRestTime)
    }
}
