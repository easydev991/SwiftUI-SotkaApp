import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct SelectedActivityViewModeTests {
    @Test("Создает .workout кейс когда activity == .workout и data != nil")
    func createsWorkoutCaseWhenActivityIsWorkoutAndDataExists() {
        let workoutData = WorkoutData(
            day: 10,
            executionType: 0,
            trainings: [
                WorkoutPreviewTraining(
                    count: 10,
                    typeId: 0,
                    sortOrder: 0
                )
            ],
            plannedCount: 4
        )
        let executionCount = 4

        let mode = SelectedActivityView.Mode(
            activity: .workout,
            data: workoutData,
            executionCount: executionCount
        )

        if case let .workout(data, count) = mode {
            #expect(data == workoutData)
            #expect(count == executionCount)
        } else {
            Issue.record("Ожидался кейс .workout, но получен другой")
        }
    }

    @Test("Создает .nonWorkout кейс когда activity == .workout но data == nil")
    func createsNonWorkoutCaseWhenActivityIsWorkoutButDataIsNil() {
        let mode = SelectedActivityView.Mode(
            activity: .workout,
            data: nil,
            executionCount: nil
        )

        if case let .nonWorkout(activity) = mode {
            #expect(activity == .workout)
        } else {
            Issue.record("Ожидался кейс .nonWorkout, но получен другой")
        }
    }

    @Test("Создает .nonWorkout кейс для активности .stretch")
    func createsNonWorkoutCaseForStretchActivity() {
        let mode = SelectedActivityView.Mode(
            activity: .stretch,
            data: nil,
            executionCount: nil
        )

        if case let .nonWorkout(activity) = mode {
            #expect(activity == .stretch)
        } else {
            Issue.record("Ожидался кейс .nonWorkout, но получен другой")
        }
    }

    @Test("Создает .nonWorkout кейс для активности .rest")
    func createsNonWorkoutCaseForRestActivity() {
        let mode = SelectedActivityView.Mode(
            activity: .rest,
            data: nil,
            executionCount: nil
        )

        if case let .nonWorkout(activity) = mode {
            #expect(activity == .rest)
        } else {
            Issue.record("Ожидался кейс .nonWorkout, но получен другой")
        }
    }

    @Test("Создает .nonWorkout кейс для активности .sick")
    func createsNonWorkoutCaseForSickActivity() {
        let mode = SelectedActivityView.Mode(
            activity: .sick,
            data: nil,
            executionCount: nil
        )

        if case let .nonWorkout(activity) = mode {
            #expect(activity == .sick)
        } else {
            Issue.record("Ожидался кейс .nonWorkout, но получен другой")
        }
    }

    @Test("isWorkout возвращает true для .workout кейса")
    func isWorkoutReturnsTrueForWorkoutCase() {
        let workoutData = WorkoutData(
            day: 10,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let mode = SelectedActivityView.Mode.workout(
            data: workoutData,
            executionCount: 4
        )

        #expect(mode.isWorkout)
    }

    @Test("isWorkout возвращает false для .nonWorkout кейса")
    func isWorkoutReturnsFalseForNonWorkoutCase() {
        let mode = SelectedActivityView.Mode.nonWorkout(.rest)

        #expect(!mode.isWorkout)
    }

    @Test("activity возвращает .workout для .workout кейса")
    func activityReturnsWorkoutForWorkoutCase() {
        let workoutData = WorkoutData(
            day: 10,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let mode = SelectedActivityView.Mode.workout(
            data: workoutData,
            executionCount: 4
        )

        #expect(mode.activity == .workout)
    }

    @Test("activity возвращает правильный тип для .nonWorkout кейса", arguments: [DayActivityType.stretch, .rest, .sick])
    func activityReturnsCorrectTypeForNonWorkoutCase(activityType: DayActivityType) {
        let mode = SelectedActivityView.Mode.nonWorkout(activityType)

        #expect(mode.activity == activityType)
    }
}
