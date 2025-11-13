import Foundation
@testable import SwiftUI_SotkaApp
import Testing
import UserNotifications

extension WorkoutScreenViewModelTests {
    @Suite("Тесты для getWorkoutResult")
    struct GetWorkoutResultTests {
        @Test("Должен возвращать результат для полной тренировки типа 'круги'")
        @MainActor
        func getWorkoutResultForCompleteCyclesWorkout() async throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            let startTime = Date().addingTimeInterval(-120)
            viewModel.workoutStartTime = startTime
            viewModel.totalRestTime = 60

            for _ in 0 ..< viewModel.stepStates.count {
                if viewModel.currentStepIndex < viewModel.stepStates.count {
                    viewModel.completeCurrentStep(appSettings: appSettings)
                    if viewModel.showTimer {
                        viewModel.onTimerCompleted(appSettings: appSettings)
                    }
                }
            }

            // Создаем уведомление перед вызовом getWorkoutResult
            let content = UNMutableNotificationContent()
            content.title = "Test"
            content.body = "Test"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            let request = UNNotificationRequest(
                identifier: "restTimerNotification",
                content: content,
                trigger: trigger
            )
            try await UNUserNotificationCenter.current().add(request)

            let result = viewModel.getWorkoutResult()
            let workoutResult = try #require(result)

            #expect(workoutResult.count == 4)
            let duration = try #require(workoutResult.duration)
            #expect(duration >= 178)
            #expect(duration <= 185)

            // Проверяем, что уведомление отменено
            let pendingAfter = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let notificationAfter = pendingAfter.first { $0.identifier == "restTimerNotification" }
            #expect(notificationAfter == nil)
        }

        @Test("Должен возвращать nil для незавершенной тренировки")
        @MainActor
        func getWorkoutResultForIncompleteWorkout() async throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            viewModel.completeCurrentStep(appSettings: appSettings)

            // Создаем уведомление перед вызовом getWorkoutResult
            let content = UNMutableNotificationContent()
            content.title = "Test"
            content.body = "Test"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            let request = UNNotificationRequest(
                identifier: "restTimerNotification",
                content: content,
                trigger: trigger
            )
            try await UNUserNotificationCenter.current().add(request)

            let result = viewModel.getWorkoutResult()
            #expect(result == nil)

            // Проверяем, что уведомление отменено даже при nil результате
            let pendingAfter = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let notificationAfter = pendingAfter.first { $0.identifier == "restTimerNotification" }
            #expect(notificationAfter == nil)
        }

        @Test("Должен правильно подсчитывать количество подходов для типа 'подходы'")
        @MainActor
        func getWorkoutResultForSets() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0),
                WorkoutPreviewTraining(count: 10, typeId: 2),
                WorkoutPreviewTraining(count: 15, typeId: 3),
                WorkoutPreviewTraining(count: 20, typeId: 4)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .sets,
                trainings: trainings,
                plannedCount: 6,
                restTime: 60
            )

            for _ in 0 ..< viewModel.stepStates.count {
                if viewModel.currentStepIndex < viewModel.stepStates.count {
                    viewModel.completeCurrentStep(appSettings: appSettings)
                    if viewModel.showTimer {
                        viewModel.onTimerCompleted(appSettings: appSettings)
                    }
                }
            }

            let result = viewModel.getWorkoutResult()
            let workoutResult = try #require(result)

            #expect(workoutResult.count == 24)
        }

        @Test("Должен возвращать duration = nil, если время начала не засечено")
        @MainActor
        func getWorkoutResultWithoutStartTime() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            viewModel.workoutStartTime = nil
            viewModel.totalRestTime = 60

            for _ in 0 ..< viewModel.stepStates.count {
                if viewModel.currentStepIndex < viewModel.stepStates.count {
                    viewModel.completeCurrentStep(appSettings: appSettings)
                    if viewModel.showTimer {
                        viewModel.onTimerCompleted(appSettings: appSettings)
                    }
                }
            }

            let result = viewModel.getWorkoutResult()
            let workoutResult = try #require(result)

            #expect(workoutResult.count == 4)
            #expect(workoutResult.duration == nil)
        }

        @Test("Должен правильно подсчитывать количество кругов для типа 'турбо'")
        @MainActor
        func getWorkoutResultForTurbo() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .turbo,
                trainings: trainings,
                plannedCount: 5,
                restTime: 60
            )

            for _ in 0 ..< viewModel.stepStates.count {
                if viewModel.currentStepIndex < viewModel.stepStates.count {
                    viewModel.completeCurrentStep(appSettings: appSettings)
                    if viewModel.showTimer {
                        viewModel.onTimerCompleted(appSettings: appSettings)
                    }
                }
            }

            let result = viewModel.getWorkoutResult()
            let workoutResult = try #require(result)

            #expect(workoutResult.count == 5)
        }

        @Test("Должен возвращать count = 0 при прерывании, если не выполнено ни одного упражнения")
        @MainActor
        func getWorkoutResultWithInterruptWhenNoExercisesCompleted() async throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            // Создаем уведомление перед вызовом getWorkoutResult
            let content = UNMutableNotificationContent()
            content.title = "Test"
            content.body = "Test"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            let request = UNNotificationRequest(
                identifier: "restTimerNotification",
                content: content,
                trigger: trigger
            )
            try await UNUserNotificationCenter.current().add(request)

            let result = viewModel.getWorkoutResult(interrupt: true)
            let workoutResult = try #require(result)

            #expect(workoutResult.count == 0)

            // Проверяем, что уведомление отменено
            let pendingAfter = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let notificationAfter = pendingAfter.first { $0.identifier == "restTimerNotification" }
            #expect(notificationAfter == nil)
        }

        @Test("Должен возвращать количество выполненных упражнений при прерывании")
        @MainActor
        func getWorkoutResultWithInterruptWhenSomeExercisesCompleted() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.onTimerCompleted(appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.onTimerCompleted(appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.onTimerCompleted(appSettings: appSettings)
            }

            let result = viewModel.getWorkoutResult(interrupt: true)
            let workoutResult = try #require(result)

            #expect(workoutResult.count == 2)
        }

        @Test("Должен вычислять длительность при прерывании")
        @MainActor
        func getWorkoutResultWithInterruptWithDuration() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            let startTime = Date().addingTimeInterval(-100)
            viewModel.workoutStartTime = startTime
            viewModel.totalRestTime = 30

            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.onTimerCompleted(appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.onTimerCompleted(appSettings: appSettings)
            }

            let result = viewModel.getWorkoutResult(interrupt: true)
            let workoutResult = try #require(result)

            #expect(workoutResult.count == 1)
            let duration = try #require(workoutResult.duration)
            #expect(duration >= 128)
            #expect(duration <= 132)
        }

        @Test("Должен возвращать duration = nil при прерывании, если время начала не засечено")
        @MainActor
        func getWorkoutResultWithInterruptWithoutStartTime() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            viewModel.workoutStartTime = nil
            viewModel.totalRestTime = 30

            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.onTimerCompleted(appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.onTimerCompleted(appSettings: appSettings)
            }

            let result = viewModel.getWorkoutResult(interrupt: true)
            let workoutResult = try #require(result)

            #expect(workoutResult.count == 1)
            #expect(workoutResult.duration == nil)
        }

        @Test("Должен работать как раньше при interrupt = false")
        @MainActor
        func getWorkoutResultWithoutInterruptStillWorksAsBefore() async throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            viewModel.completeCurrentStep(appSettings: appSettings)

            // Создаем уведомление перед вызовом getWorkoutResult
            let content = UNMutableNotificationContent()
            content.title = "Test"
            content.body = "Test"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            let request = UNNotificationRequest(
                identifier: "restTimerNotification",
                content: content,
                trigger: trigger
            )
            try await UNUserNotificationCenter.current().add(request)

            let result = viewModel.getWorkoutResult(interrupt: false)
            #expect(result == nil)

            // Проверяем, что уведомление отменено даже при nil результате
            let pendingAfter = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let notificationAfter = pendingAfter.first { $0.identifier == "restTimerNotification" }
            #expect(notificationAfter == nil)
        }
    }
}
