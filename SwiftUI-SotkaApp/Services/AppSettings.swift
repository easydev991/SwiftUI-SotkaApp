//
//  AppSettings.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 04.05.2025.
//

import SwiftUI
import Observation

@Observable final class AppSettings {
    var showNotificationError = false
    var notificationError: NotificationError?

    var appTheme: AppTheme {
        get {
            access(keyPath: \.appTheme)
            let rawValue = UserDefaults.standard.integer(forKey: "appTheme")
            return .init(rawValue: rawValue) ?? .system
        }
        set {
            withMutation(keyPath: \.appTheme) {
                UserDefaults.standard.setValue(newValue.rawValue, forKey: "appTheme")
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

    let appVersion = (
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
    ) ?? "4.0.0"

    @MainActor
    func setWorkoutNotificationsEnabled(_ enabled: Bool) {
        guard enabled else {
            workoutNotificationsEnabled = false
            removePendingNotifications()
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

    private func checkNotificationPermissions() async -> Bool {
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

    private func scheduleDailyNotification() {
        removePendingNotifications()

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Workout Reminder", comment: "")
        content.body = NSLocalizedString("Time for your daily workout!", comment: "")
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
            identifier: "dailyWorkoutReminder",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func removePendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private var defaultNotificationTime: Date {
        var components = DateComponents()
        components.hour = 19
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
}

enum NotificationError: Error, LocalizedError {
    case denied

    var errorDescription: String? {
        NSLocalizedString("Notification permission denied", comment: "")
    }
}

extension AppSettings {
    private enum Key: String {
        case appTheme
        /// Тоггл для ежедневных уведомлений о тренировках
        ///
        /// Значение взял из старого приложения
        case workoutNotificationsEnabled = "WorkoutTrainNotification"
        /// Время ежедневного уведомления о тренировке
        ///
        /// Значение взял из старого приложения
        case workoutNotificationTime = "WorkoutTrainNotificationDate"
    }
}
