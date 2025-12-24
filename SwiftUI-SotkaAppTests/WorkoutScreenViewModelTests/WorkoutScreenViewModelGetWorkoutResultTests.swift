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
                        viewModel.handleTimerFinish(force: false, appSettings: appSettings)
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
            // Учитываем время выполнения кода между установкой startTime и вызовом getWorkoutResult
            // startTime установлен на -120 секунд, totalRestTime = 60, ожидаем примерно 180 секунд
            // Добавляем запас для времени выполнения кода (цикл, создание уведомления и т.д.)
            #expect(duration >= 178)
            #expect(duration <= 190)

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
                        viewModel.handleTimerFinish(force: false, appSettings: appSettings)
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
                        viewModel.handleTimerFinish(force: false, appSettings: appSettings)
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
                        viewModel.handleTimerFinish(force: false, appSettings: appSettings)
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
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
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
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
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
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
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

        @Test("Для executionType = .sets и interrupt = true должен возвращать WorkoutResult с count = plannedCount")
        @MainActor
        func getWorkoutResultForSetsWithInterruptShouldReturnPlannedCount() async throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0),
                WorkoutPreviewTraining(count: 10, typeId: 2)
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

            // Завершаем только 2 подхода из 12 (6 подходов * 2 упражнения)
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
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

            let result = viewModel.getWorkoutResult(interrupt: true)
            let workoutResult = try #require(result)

            // Для прерванной тренировки с подходами должен возвращать plannedCount
            #expect(workoutResult.count == 6)

            // Проверяем, что уведомление отменено
            let pendingAfter = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let notificationAfter = pendingAfter.first { $0.identifier == "restTimerNotification" }
            #expect(notificationAfter == nil)
        }

        @Test(
            "Для executionType = .sets и interrupt = false должен возвращать WorkoutResult с count равным количеству всех этапов упражнений"
        )
        @MainActor
        func getWorkoutResultForSetsWithoutInterruptShouldReturnAllSteps() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0),
                WorkoutPreviewTraining(count: 10, typeId: 2)
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

            // Завершаем все этапы тренировки
            for _ in 0 ..< viewModel.stepStates.count {
                if viewModel.currentStepIndex < viewModel.stepStates.count {
                    viewModel.completeCurrentStep(appSettings: appSettings)
                    if viewModel.showTimer {
                        viewModel.handleTimerFinish(force: false, appSettings: appSettings)
                    }
                }
            }

            let result = viewModel.getWorkoutResult(interrupt: false)
            let workoutResult = try #require(result)

            // Для завершенной тренировки с подходами должен возвращать количество всех этапов (6 подходов * 2 упражнения = 12)
            #expect(workoutResult.count == 12)
        }

        @Test("Для executionType = .cycles и interrupt = true должен возвращать WorkoutResult с count равным количеству завершенных этапов")
        @MainActor
        func getWorkoutResultForCyclesWithInterruptShouldReturnCompletedSteps() throws {
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

            // Завершаем warmUp и 2 круга из 4
            viewModel.completeCurrentStep(appSettings: appSettings) // warmUp
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings) // круг 1
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings) // круг 2
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }

            let result = viewModel.getWorkoutResult(interrupt: true)
            let workoutResult = try #require(result)

            // Для прерванной тренировки с кругами должен возвращать количество завершенных кругов (прежняя логика)
            #expect(workoutResult.count == 2)
        }

        @Test(
            "Для executionType = .cycles и interrupt = false должен возвращать WorkoutResult с count равным количеству всех этапов упражнений"
        )
        @MainActor
        func getWorkoutResultForCyclesWithoutInterruptShouldReturnAllSteps() throws {
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

            // Завершаем все этапы тренировки
            for _ in 0 ..< viewModel.stepStates.count {
                if viewModel.currentStepIndex < viewModel.stepStates.count {
                    viewModel.completeCurrentStep(appSettings: appSettings)
                    if viewModel.showTimer {
                        viewModel.handleTimerFinish(force: false, appSettings: appSettings)
                    }
                }
            }

            let result = viewModel.getWorkoutResult(interrupt: false)
            let workoutResult = try #require(result)

            // Для завершенной тренировки с кругами должен возвращать количество всех этапов
            #expect(workoutResult.count == 4)
        }

        @Test("Для executionType = .turbo с подходами и interrupt = true должен возвращать WorkoutResult с count = plannedCount")
        @MainActor
        func getWorkoutResultForTurboWithSetsAndInterruptShouldReturnPlannedCount() async throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0),
                WorkoutPreviewTraining(count: 10, typeId: 2)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            // День 93 - турбо-день с подходами
            viewModel.setupWorkoutData(
                dayNumber: 93,
                executionType: .turbo,
                trainings: trainings,
                plannedCount: 1,
                restTime: 60
            )

            // Завершаем только 1 подход из 2 (1 подход * 2 упражнения)
            viewModel.completeCurrentStep(appSettings: appSettings)
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
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

            let result = viewModel.getWorkoutResult(interrupt: true)
            let workoutResult = try #require(result)

            // Для прерванной турбо-тренировки с подходами должен возвращать plannedCount
            #expect(workoutResult.count == 1)

            // Проверяем, что уведомление отменено
            let pendingAfter = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let notificationAfter = pendingAfter.first { $0.identifier == "restTimerNotification" }
            #expect(notificationAfter == nil)
        }

        @Test(
            "Для executionType = .turbo с кругами и interrupt = true должен возвращать WorkoutResult с count равным количеству завершенных этапов"
        )
        @MainActor
        func getWorkoutResultForTurboWithCyclesAndInterruptShouldReturnCompletedSteps() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            // День 1 - турбо-день с кругами
            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .turbo,
                trainings: trainings,
                plannedCount: 5,
                restTime: 60
            )

            // Завершаем warmUp и 2 круга из 5
            viewModel.completeCurrentStep(appSettings: appSettings) // warmUp
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings) // круг 1
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            viewModel.completeCurrentStep(appSettings: appSettings) // круг 2
            if viewModel.showTimer {
                viewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }

            let result = viewModel.getWorkoutResult(interrupt: true)
            let workoutResult = try #require(result)

            // Для прерванной турбо-тренировки с кругами должен возвращать количество завершенных кругов (прежняя логика)
            #expect(workoutResult.count == 2)
        }
    }
}
