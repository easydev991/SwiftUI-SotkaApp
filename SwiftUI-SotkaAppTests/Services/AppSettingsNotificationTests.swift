import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
struct AppSettingsNotificationTests {
    private let notificationsEnabledKey = "WorkoutTrainNotification"
    private let notificationTimeKey = "WorkoutTrainNotificationDate"

    @Test("Ежедневные уведомления управляются только флагом и временем")
    func notificationsAreDrivenOnlyByOwnSettings() throws {
        let userDefaults = try MockUserDefaults.create()
        let settings = AppSettings(userDefaults: userDefaults)

        let notificationTime = Date(timeIntervalSinceReferenceDate: 123_456)
        settings.workoutNotificationsEnabled = false
        settings.workoutNotificationTime = notificationTime

        let enabledBefore = userDefaults.bool(forKey: notificationsEnabledKey)
        let timeBefore = userDefaults.double(forKey: notificationTimeKey)

        settings.restTime = 75
        settings.appTheme = .dark

        let enabledAfter = userDefaults.bool(forKey: notificationsEnabledKey)
        let timeAfter = userDefaults.double(forKey: notificationTimeKey)

        #expect(enabledBefore == enabledAfter)
        #expect(timeBefore == timeAfter)
    }

    @Test("Изменение флага уведомлений не меняет выбранное время")
    func changingEnabledFlagDoesNotOverrideNotificationTime() throws {
        let userDefaults = try MockUserDefaults.create()
        let settings = AppSettings(userDefaults: userDefaults)

        let notificationTime = Date(timeIntervalSinceReferenceDate: 987_654)
        settings.workoutNotificationsEnabled = false
        settings.workoutNotificationTime = notificationTime

        let timeBefore = userDefaults.double(forKey: notificationTimeKey)

        settings.workoutNotificationsEnabled = true
        settings.workoutNotificationsEnabled = false

        let timeAfter = userDefaults.double(forKey: notificationTimeKey)

        #expect(timeBefore == timeAfter)
    }
}
