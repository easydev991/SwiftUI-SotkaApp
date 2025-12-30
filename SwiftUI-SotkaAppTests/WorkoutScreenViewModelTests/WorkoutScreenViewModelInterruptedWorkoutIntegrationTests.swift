import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing
import UserNotifications

extension WorkoutScreenViewModelTests {
    @Suite("Интеграционные тесты для прерванных тренировок")
    struct InterruptedWorkoutIntegrationTests {
        @Test(
            "Прерывание тренировки с подходами → getWorkoutResult возвращает plannedCount → handleWorkoutResult устанавливает count = plannedCount → displayedCount возвращает plannedCount"
        )
        @MainActor
        func interruptedSetsWorkoutFullCycle() async throws {
            // Настройка WorkoutScreenViewModel
            let workoutViewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0),
                WorkoutPreviewTraining(count: 10, typeId: 2)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            workoutViewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .sets,
                trainings: trainings,
                plannedCount: 6,
                restTime: 60
            )

            // Завершаем только часть подходов
            workoutViewModel.completeCurrentStep(appSettings: appSettings) // warmUp
            if workoutViewModel.showTimer {
                workoutViewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            workoutViewModel.completeCurrentStep(appSettings: appSettings) // первый подход
            if workoutViewModel.showTimer {
                workoutViewModel.handleTimerFinish(force: false, appSettings: appSettings)
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

            // getWorkoutResult(interrupt: true) возвращает plannedCount для подходов
            let result = workoutViewModel.getWorkoutResult(interrupt: true)
            let workoutResult = try #require(result)
            #expect(workoutResult.count == 6) // plannedCount

            // Настройка WorkoutPreviewViewModel
            let previewViewModel = WorkoutPreviewViewModel()
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            previewViewModel.updateData(modelContext: context, day: 1, restTime: 60)
            previewViewModel.plannedCount = 6

            // handleWorkoutResult устанавливает count = plannedCount (из результата)
            previewViewModel.handleWorkoutResult(workoutResult)
            let count = try #require(previewViewModel.count)
            #expect(count == 6) // plannedCount из результата

            // displayedCount возвращает plannedCount
            let displayedCount = try #require(previewViewModel.displayedCount)
            #expect(displayedCount == 6) // plannedCount

            // Проверяем, что уведомление отменено
            let pendingAfter = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let notificationAfter = pendingAfter.first { $0.identifier == "restTimerNotification" }
            #expect(notificationAfter == nil)
        }

        @Test(
            "Завершение тренировки с подходами → getWorkoutResult возвращает фактическое количество → handleWorkoutResult устанавливает count → displayedCount возвращает count"
        )
        @MainActor
        func completedSetsWorkoutFullCycle() throws {
            // Настройка WorkoutScreenViewModel
            let workoutViewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0),
                WorkoutPreviewTraining(count: 10, typeId: 2)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            workoutViewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .sets,
                trainings: trainings,
                plannedCount: 6,
                restTime: 60
            )

            // Завершаем все этапы тренировки
            for _ in 0 ..< workoutViewModel.stepStates.count {
                if workoutViewModel.currentStepIndex < workoutViewModel.stepStates.count {
                    workoutViewModel.completeCurrentStep(appSettings: appSettings)
                    if workoutViewModel.showTimer {
                        workoutViewModel.handleTimerFinish(force: false, appSettings: appSettings)
                    }
                }
            }

            // getWorkoutResult(interrupt: false) возвращает фактическое количество
            let result = workoutViewModel.getWorkoutResult(interrupt: false)
            let workoutResult = try #require(result)
            #expect(workoutResult.count == 12) // 6 подходов * 2 упражнения

            // Настройка WorkoutPreviewViewModel
            let previewViewModel = WorkoutPreviewViewModel()
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            previewViewModel.updateData(modelContext: context, day: 1, restTime: 60)
            previewViewModel.plannedCount = 6

            // handleWorkoutResult устанавливает count равным фактическому количеству
            previewViewModel.handleWorkoutResult(workoutResult)
            let count = try #require(previewViewModel.count)
            #expect(count == 12) // фактическое количество из результата

            // displayedCount возвращает count
            let displayedCount = try #require(previewViewModel.displayedCount)
            #expect(displayedCount == 12) // count
        }

        @Test(
            "Прерывание тренировки с кругами → getWorkoutResult возвращает количество завершенных кругов → handleWorkoutResult устанавливает count → displayedCount возвращает count (прежняя логика)"
        )
        @MainActor
        func interruptedCyclesWorkoutFullCycle() throws {
            // Настройка WorkoutScreenViewModel
            let workoutViewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            let appSettings = AppSettings(userDefaults: userDefaults)

            workoutViewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            // Завершаем warmUp и 2 круга из 4
            workoutViewModel.completeCurrentStep(appSettings: appSettings) // warmUp
            if workoutViewModel.showTimer {
                workoutViewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            workoutViewModel.completeCurrentStep(appSettings: appSettings) // круг 1
            if workoutViewModel.showTimer {
                workoutViewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }
            workoutViewModel.completeCurrentStep(appSettings: appSettings) // круг 2
            if workoutViewModel.showTimer {
                workoutViewModel.handleTimerFinish(force: false, appSettings: appSettings)
            }

            // getWorkoutResult(interrupt: true) возвращает количество завершенных кругов
            let result = workoutViewModel.getWorkoutResult(interrupt: true)
            let workoutResult = try #require(result)
            #expect(workoutResult.count == 2) // количество завершенных кругов

            // Настройка WorkoutPreviewViewModel
            let previewViewModel = WorkoutPreviewViewModel()
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            previewViewModel.updateData(modelContext: context, day: 1, restTime: 60)
            previewViewModel.plannedCount = 4

            // handleWorkoutResult устанавливает count равным количеству завершенных кругов
            previewViewModel.handleWorkoutResult(workoutResult)
            let count = try #require(previewViewModel.count)
            #expect(count == 2) // количество завершенных кругов из результата

            // displayedCount возвращает count (прежняя логика)
            let displayedCount = try #require(previewViewModel.displayedCount)
            #expect(displayedCount == 2) // count
        }
    }
}
