import Foundation
@testable import SwiftUI_SotkaApp
import Testing
import UserNotifications

extension WorkoutScreenViewModelTests {
    @Suite("Тесты для checkAndHandleExpiredRestTimer")
    struct ExpiredTimerTests {
        @Test("Должен ничего не делать, если таймер не показывается")
        @MainActor
        func checkAndHandleExpiredRestTimerWhenTimerNotShowing() throws {
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

            viewModel.showTimer = false
            viewModel.currentRestStartTime = Date().addingTimeInterval(-70)

            let initialStepIndex = viewModel.currentStepIndex
            let initialTotalRestTime = viewModel.totalRestTime

            viewModel.checkAndHandleExpiredRestTimer(appSettings: appSettings)

            #expect(viewModel.currentStepIndex == initialStepIndex)
            #expect(viewModel.totalRestTime == initialTotalRestTime)
            #expect(!viewModel.showTimer)
        }

        @Test("Должен ничего не делать, если время начала отдыха не установлено")
        @MainActor
        func checkAndHandleExpiredRestTimerWhenRestStartTimeIsNil() throws {
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
            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.showTimer)
            viewModel.currentRestStartTime = nil

            let initialStepIndex = viewModel.currentStepIndex
            let initialTotalRestTime = viewModel.totalRestTime

            viewModel.checkAndHandleExpiredRestTimer(appSettings: appSettings)

            #expect(viewModel.currentStepIndex == initialStepIndex)
            #expect(viewModel.totalRestTime == initialTotalRestTime)
            #expect(viewModel.showTimer)
        }

        @Test("Должен ничего не делать, если таймер еще не истек")
        @MainActor
        func checkAndHandleExpiredRestTimerWhenTimerNotExpired() throws {
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
            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.showTimer)
            viewModel.currentRestStartTime = Date().addingTimeInterval(-30)

            let initialStepIndex = viewModel.currentStepIndex
            let initialTotalRestTime = viewModel.totalRestTime

            viewModel.checkAndHandleExpiredRestTimer(appSettings: appSettings)

            #expect(viewModel.currentStepIndex == initialStepIndex)
            #expect(viewModel.totalRestTime == initialTotalRestTime)
            #expect(viewModel.showTimer)
        }

        @Test("Должен закрыть таймер и обновить состояние, если таймер истек")
        @MainActor
        func checkAndHandleExpiredRestTimerWhenTimerExpired() async throws {
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
            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.showTimer)
            #expect(viewModel.currentStepIndex == 2)
            #expect(viewModel.stepStates[2].state == .inactive)

            let restStartTime = Date().addingTimeInterval(-70)
            viewModel.currentRestStartTime = restStartTime
            let initialTotalRestTime = viewModel.totalRestTime

            viewModel.checkAndHandleExpiredRestTimer(appSettings: appSettings)

            #expect(!viewModel.showTimer)
            #expect(viewModel.stepStates[2].state == .active)
            #expect(viewModel.currentRestStartTime == nil)
            #expect(viewModel.totalRestTime >= initialTotalRestTime + 69)
            #expect(viewModel.totalRestTime <= initialTotalRestTime + 71)

            let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let restTimerNotification = pendingNotifications.first { $0.identifier == "restTimerNotification" }
            #expect(restTimerNotification == nil)
        }

        @Test("Должен закрыть таймер точно в момент истечения")
        @MainActor
        func checkAndHandleExpiredRestTimerExactlyAtExpiration() throws {
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
            viewModel.completeCurrentStep(appSettings: appSettings)

            #expect(viewModel.showTimer)

            let restStartTime = Date().addingTimeInterval(-60)
            viewModel.currentRestStartTime = restStartTime
            let initialTotalRestTime = viewModel.totalRestTime

            viewModel.checkAndHandleExpiredRestTimer(appSettings: appSettings)

            #expect(!viewModel.showTimer)
            #expect(viewModel.currentRestStartTime == nil)
            #expect(viewModel.totalRestTime >= initialTotalRestTime + 59)
            #expect(viewModel.totalRestTime <= initialTotalRestTime + 61)
        }
    }
}
