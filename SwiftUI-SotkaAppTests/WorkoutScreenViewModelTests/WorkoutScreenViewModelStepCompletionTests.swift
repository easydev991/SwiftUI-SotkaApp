import Foundation
@testable import SwiftUI_SotkaApp
import Testing
import UserNotifications

extension WorkoutScreenViewModelTests {
    @Suite("Тесты для completeCurrentStep и handleTimerFinish")
    struct StepCompletionTests {
        @Test("Должен завершать текущий этап, показывать таймер и планировать уведомление, НЕ обновляя состояние следующего этапа")
        @MainActor
        func completeCurrentStep() async throws {
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

            viewModel.currentStepIndex = 1

            #expect(viewModel.currentStepIndex == 1)
            #expect(viewModel.stepStates[1].state == .inactive)

            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.stepStates[1].state == .completed)
            #expect(viewModel.currentStepIndex == 2)
            #expect(viewModel.stepStates[2].state == .inactive)
            #expect(viewModel.showTimer)

            let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            let notification = try #require(restTimerNotification)
            #expect(notification.identifier == "restTimerNotification")
        }

        @Test("Должен завершать последний этап (coolDown), не показывать таймер и не планировать уведомление")
        @MainActor
        func completeCurrentStepForLastStep() async throws {
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

            let lastIndex = viewModel.stepStates.count - 1
            let preLastIndex = lastIndex - 1
            viewModel.currentStepIndex = preLastIndex

            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.stepStates[preLastIndex].state == .completed)
            #expect(viewModel.stepStates[lastIndex].state == .active)
            #expect(!viewModel.showTimer)

            let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            #expect(restTimerNotification == nil)
        }

        @Test(
            "Должен отменять уведомление, скрывать таймер, учитывать время отдыха, обновлять состояние следующего этапа, воспроизводить звук/вибрацию и продолжать тренировку"
        )
        @MainActor
        func handleTimerFinish() async throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            userDefaults.set(true, forKey: "playTimerSound")
            userDefaults.set(true, forKey: "vibrate")
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            viewModel.currentStepIndex = 1

            #expect(viewModel.currentStepIndex == 1)
            #expect(viewModel.stepStates[1].state == .inactive)

            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.stepStates[1].state == .completed)
            #expect(viewModel.currentStepIndex == 2)
            #expect(viewModel.stepStates[2].state == .inactive)
            #expect(viewModel.showTimer)

            var pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            var restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            let notification = try #require(restTimerNotification)
            #expect(notification.identifier == "restTimerNotification")

            viewModel.currentRestStartTime = Date().addingTimeInterval(-30)

            let initialTotalRestTime = viewModel.totalRestTime

            viewModel.handleTimerFinish(force: false, appSettings: appSettings)

            pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            #expect(restTimerNotification == nil)

            #expect(!viewModel.showTimer)
            #expect(viewModel.totalRestTime >= initialTotalRestTime + 29)
            #expect(viewModel.totalRestTime <= initialTotalRestTime + 31)
            #expect(viewModel.currentRestStartTime == nil)

            #expect(viewModel.stepStates[2].state == .active)

            let currentStep = try #require(viewModel.currentStep)
            let currentStepState = viewModel.stepStates.first { $0.step.id == currentStep.id }
            let stepState = try #require(currentStepState)
            #expect(stepState.state == .active)
        }

        @Test("Должен НЕ показывать таймер отдыха после warmUp")
        @MainActor
        func completeCurrentStepDoesNotShowTimerAfterWarmUp() async throws {
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

            #expect(viewModel.currentStepIndex == 0)
            #expect(viewModel.stepStates[0].state == .active)

            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.stepStates[0].state == .completed)
            #expect(viewModel.currentStepIndex == 1)
            #expect(!viewModel.showTimer)
            #expect(viewModel.stepStates[1].state == .active)

            let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            #expect(restTimerNotification == nil)
        }

        @Test("Должен НЕ показывать таймер отдыха перед coolDown")
        @MainActor
        func completeCurrentStepDoesNotShowTimerBeforeCoolDown() async throws {
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

            let lastIndex = viewModel.stepStates.count - 1
            let preLastIndex = lastIndex - 1
            viewModel.currentStepIndex = preLastIndex

            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.stepStates[preLastIndex].state == .completed)
            #expect(viewModel.currentStepIndex == lastIndex)
            #expect(!viewModel.showTimer)
            #expect(viewModel.stepStates[lastIndex].state == .active)

            let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            #expect(restTimerNotification == nil)
        }

        @Test("Должен показывать таймер отдыха после обычного круга")
        @MainActor
        func completeCurrentStepShowsTimerAfterRegularStep() async throws {
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

            viewModel.currentStepIndex = 1

            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.stepStates[1].state == .completed)
            #expect(viewModel.currentStepIndex == 2)
            #expect(viewModel.showTimer)

            let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            let notification = try #require(restTimerNotification)
            #expect(notification.identifier == "restTimerNotification")
        }

        @Test(
            "Должен отменять уведомление, скрывать таймер, учитывать время отдыха, обновлять состояние следующего этапа, воспроизводить звук/вибрацию при force = false"
        )
        @MainActor
        func handleTimerFinishWithForceFalse() async throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            userDefaults.set(true, forKey: "playTimerSound")
            userDefaults.set(true, forKey: "vibrate")
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            viewModel.currentStepIndex = 1

            #expect(viewModel.currentStepIndex == 1)
            #expect(viewModel.stepStates[1].state == .inactive)

            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.stepStates[1].state == .completed)
            #expect(viewModel.currentStepIndex == 2)
            #expect(viewModel.stepStates[2].state == .inactive)
            #expect(viewModel.showTimer)

            var pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            var restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            let notification = try #require(restTimerNotification)
            #expect(notification.identifier == "restTimerNotification")

            viewModel.currentRestStartTime = Date().addingTimeInterval(-30)

            let initialTotalRestTime = viewModel.totalRestTime

            viewModel.handleTimerFinish(force: false, appSettings: appSettings)

            pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            #expect(restTimerNotification == nil)

            #expect(!viewModel.showTimer)
            #expect(viewModel.totalRestTime >= initialTotalRestTime + 29)
            #expect(viewModel.totalRestTime <= initialTotalRestTime + 31)
            #expect(viewModel.currentRestStartTime == nil)

            #expect(viewModel.stepStates[2].state == .active)

            let currentStep = try #require(viewModel.currentStep)
            let currentStepState = viewModel.stepStates.first { $0.step.id == currentStep.id }
            let stepState = try #require(currentStepState)
            #expect(stepState.state == .active)
        }

        @Test(
            "Должен отменять уведомление, скрывать таймер, учитывать время отдыха, обновлять состояние следующего этапа, НЕ воспроизводить звук/вибрацию при force = true"
        )
        @MainActor
        func handleTimerFinishWithForceTrue() async throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]
            let userDefaults = try MockUserDefaults.create()
            userDefaults.set(true, forKey: "playTimerSound")
            userDefaults.set(true, forKey: "vibrate")
            let appSettings = AppSettings(userDefaults: userDefaults)

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            viewModel.currentStepIndex = 1

            #expect(viewModel.currentStepIndex == 1)
            #expect(viewModel.stepStates[1].state == .inactive)

            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.stepStates[1].state == .completed)
            #expect(viewModel.currentStepIndex == 2)
            #expect(viewModel.stepStates[2].state == .inactive)
            #expect(viewModel.showTimer)

            var pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            var restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            let notification = try #require(restTimerNotification)
            #expect(notification.identifier == "restTimerNotification")

            viewModel.currentRestStartTime = Date().addingTimeInterval(-30)

            let initialTotalRestTime = viewModel.totalRestTime

            viewModel.handleTimerFinish(force: true, appSettings: appSettings)

            pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            #expect(restTimerNotification == nil)

            #expect(!viewModel.showTimer)
            #expect(viewModel.totalRestTime >= initialTotalRestTime + 29)
            #expect(viewModel.totalRestTime <= initialTotalRestTime + 31)
            #expect(viewModel.currentRestStartTime == nil)

            #expect(viewModel.stepStates[2].state == .active)

            let currentStep = try #require(viewModel.currentStep)
            let currentStepState = viewModel.stepStates.first { $0.step.id == currentStep.id }
            let stepState = try #require(currentStepState)
            #expect(stepState.state == .active)
        }
    }
}
