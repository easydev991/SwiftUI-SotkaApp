//
//  AppSettings.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 04.05.2025.
//

import SwiftUI
import Observation
import SWUtils

@Observable final class AppSettings {
    private let audioPlayer = AudioPlayerManager(fileName: "timerSound", fileExtension: "mp3")
    private let vibrationService = VibrationService()
    let appVersion = (
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    ) ?? "4.0.0"
    var showLanguageAlert = false
    var showNotificationError = false
    var notificationError: NotificationError?

    var appTheme: AppTheme {
        get {
            access(keyPath: \.appTheme)
            let rawValue = UserDefaults.standard.integer(forKey: Key.appTheme.rawValue)
            return .init(rawValue: rawValue) ?? .system
        }
        set {
            withMutation(keyPath: \.appTheme) {
                UserDefaults.standard.setValue(
                    newValue.rawValue,
                    forKey: Key.appTheme.rawValue
                )
            }
        }
    }

    var workoutNotificationsEnabled: Bool {
        get {
            access(keyPath: \.workoutNotificationsEnabled)
            return UserDefaults.standard.bool(
                forKey: Key.workoutNotificationsEnabled.rawValue
            )
        }
        set {
            withMutation(keyPath: \.workoutNotificationsEnabled) {
                UserDefaults.standard.set(
                    newValue,
                    forKey: Key.workoutNotificationsEnabled.rawValue
                )
            }
        }
    }

    var workoutNotificationTime: Date {
        get {
            access(keyPath: \.workoutNotificationTime)
            let storedTime = UserDefaults.standard.double(
                forKey: Key.workoutNotificationTime.rawValue
            )
            return storedTime == 0
            ? defaultNotificationTime
            : Date(timeIntervalSinceReferenceDate: storedTime)
        }
        set {
            withMutation(keyPath: \.workoutNotificationTime) {
                UserDefaults.standard.set(
                    newValue.timeIntervalSinceReferenceDate,
                    forKey: Key.workoutNotificationTime.rawValue
                )
            }
            if workoutNotificationsEnabled {
                scheduleDailyNotification()
            }
        }
    }
    
    var playTimerSound: Bool {
        get {
            access(keyPath: \.playTimerSound)
            return UserDefaults.standard.bool(forKey: Key.playTimerSound.rawValue)
        }
        set {
            withMutation(keyPath: \.playTimerSound) {
                UserDefaults.standard.set(newValue, forKey: Key.playTimerSound.rawValue)
            }
            if newValue { audioPlayer.play() }
        }
    }
    
    @MainActor
    var vibrate: Bool {
        get {
            access(keyPath: \.vibrate)
            return UserDefaults.standard.bool(forKey: Key.vibrate.rawValue)
        }
        set {
            withMutation(keyPath: \.vibrate) {
                UserDefaults.standard.set(newValue, forKey: Key.vibrate.rawValue)
            }
            if newValue {
                vibrationService.perform()
            }
        }
    }

    @MainActor
    func setWorkoutNotificationsEnabled(_ enabled: Bool) {
        guard enabled else {
            workoutNotificationsEnabled = false
            removePendingDailyNotifications()
            return
        }
        Task {
            let granted = await checkNotificationPermissions()
            workoutNotificationsEnabled = granted
            if granted {
                scheduleDailyNotification()
            } else {
                showNotificationError = true
                notificationError = .denied
            }
        }
    }
    
    @MainActor
    func sendFeedback() {
        let subject = "\(ProcessInfo.processInfo.processName): Обратная связь"
        let question = "Над чем нам стоит поработать?"
        let sysVersion = "iOS: \(ProcessInfo.processInfo.operatingSystemVersionString)"
        let appVersion = "App version: " + appVersion
        let body = """
            \(sysVersion)
            \(appVersion)
            \(question)
            \n
        """
        FeedbackSender.sendFeedback(
            subject: subject,
            messageBody: body,
            recipients: ["info@workout.su"]
        )
    }
}

enum NotificationError: Error, LocalizedError {
    case denied

    var errorDescription: String? {
        NSLocalizedString("Error.NotificationPermission", comment: "")
    }
}

private extension AppSettings {
    enum Key: String {
        case appTheme
        /// Ежедневные уведомления о тренировках
        ///
        /// Значение взял из старого приложения
        case workoutNotificationsEnabled = "WorkoutTrainNotification"
        /// Время ежедневного уведомления о тренировке
        ///
        /// Значение взял из старого приложения
        case workoutNotificationTime = "WorkoutTrainNotificationDate"
        /// Воспроизводить звук по окончании отдыха
        ///
        /// Значение взял из старого приложения
        case playTimerSound = "WorkoutPlayTimerSound"
        /// Вибрировать по окончании отдыха
        ///
        /// Значение взял из старого приложения
        case vibrate = "WorkoutPlayVibrate"
        /// Идентификатор для ежедневного уведомления
        case dailyWorkoutReminder
    }
}

private extension AppSettings {
    func checkNotificationPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                return false
            }
        default:
            return false
        }
    }

    func scheduleDailyNotification() {
        removePendingDailyNotifications()

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Notification.DailyWorkoutTitle", comment: "")
        content.body = NSLocalizedString("Notification.DailyWorkoutBody", comment: "")
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: workoutNotificationTime
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: Key.dailyWorkoutReminder.rawValue,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func removePendingDailyNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Key.dailyWorkoutReminder.rawValue]
        )
    }

    var defaultNotificationTime: Date {
        var components = DateComponents()
        components.hour = 19
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
}
