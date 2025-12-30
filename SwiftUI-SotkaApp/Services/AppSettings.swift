import Observation
import OSLog
import SwiftUI
import SWUtils

@Observable
@MainActor
final class AppSettings {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
        category: String(describing: AppSettings.self)
    )
    private let notificationCenter = UNUserNotificationCenter.current()
    private let audioPlayer = AudioPlayerManager()
    let appVersion = Constants.appVersion
    var showLanguageAlert = false
    var showNotificationError = false
    var notificationError: NotificationError?

    init(userDefaults: UserDefaults? = nil) {
        self.defaults = userDefaults ?? UserDefaults.standard
    }

    var appTheme: AppTheme {
        get {
            access(keyPath: \.appTheme)
            let rawValue = defaults.integer(forKey: Key.appTheme.rawValue)
            return .init(rawValue: rawValue) ?? .system
        }
        set {
            withMutation(keyPath: \.appTheme) {
                defaults.setValue(
                    newValue.rawValue,
                    forKey: Key.appTheme.rawValue
                )
            }
        }
    }

    var workoutNotificationsEnabled: Bool {
        get {
            access(keyPath: \.workoutNotificationsEnabled)
            return defaults.bool(
                forKey: Key.workoutNotificationsEnabled.rawValue
            )
        }
        set {
            withMutation(keyPath: \.workoutNotificationsEnabled) {
                defaults.set(
                    newValue,
                    forKey: Key.workoutNotificationsEnabled.rawValue
                )
            }
        }
    }

    var workoutNotificationTime: Date {
        get {
            access(keyPath: \.workoutNotificationTime)
            let storedTime = defaults.double(
                forKey: Key.workoutNotificationTime.rawValue
            )
            return storedTime == 0
                ? defaultNotificationTime
                : Date(timeIntervalSinceReferenceDate: storedTime)
        }
        set {
            withMutation(keyPath: \.workoutNotificationTime) {
                defaults.set(
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
            return defaults.bool(forKey: Key.playTimerSound.rawValue)
        }
        set {
            withMutation(keyPath: \.playTimerSound) {
                defaults.set(newValue, forKey: Key.playTimerSound.rawValue)
            }
            if newValue {
                audioPlayer.setupSound(timerSound)
                audioPlayer.play()
            } else {
                audioPlayer.stop()
            }
        }
    }

    var timerSound: TimerSound {
        get {
            access(keyPath: \.timerSound)
            guard let rawValue = defaults.string(forKey: Key.timerSound.rawValue),
                  let sound = TimerSound(rawValue: rawValue)
            else {
                return .ringtone1
            }
            return sound
        }
        set {
            withMutation(keyPath: \.timerSound) {
                defaults.set(newValue.rawValue, forKey: Key.timerSound.rawValue)
            }
            audioPlayer.setupSound(newValue)
            audioPlayer.play()
        }
    }

    var vibrate: Bool {
        get {
            access(keyPath: \.vibrate)
            return defaults.bool(forKey: Key.vibrate.rawValue)
        }
        set {
            withMutation(keyPath: \.vibrate) {
                defaults.set(newValue, forKey: Key.vibrate.rawValue)
            }
            if newValue {
                VibrationService.perform()
            }
        }
    }

    var restTime: Int {
        get {
            access(keyPath: \.restTime)
            let storedValue = defaults.integer(forKey: Constants.restTimeKey)
            return storedValue == 0 ? Constants.defaultRestTime : storedValue
        }
        set {
            withMutation(keyPath: \.restTime) {
                defaults.set(newValue, forKey: Constants.restTimeKey)
            }
        }
    }

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

    func sendFeedback(message: String? = nil) {
        FeedbackSender.sendFeedback(
            subject: CommonFeedback.subject,
            messageBody: CommonFeedback.makeBody(for: message),
            recipients: Constants.feedbackRecipients
        )
    }

    /// Синхронизирует настройки уведомлений с реальными разрешениями системы
    func syncNotificationSettings() async {
        let settings = await notificationCenter.notificationSettings()
        switch settings.authorizationStatus {
        case .denied:
            if workoutNotificationsEnabled {
                workoutNotificationsEnabled = false
                showNotificationError = true
                notificationError = .denied
                logger.info("Уведомления отключены: разрешения отозваны в системных настройках")
            }
            let pendingRequests = await notificationCenter.pendingNotificationRequests()
            if pendingRequests.contains(where: { $0.identifier == Key.dailyWorkoutReminder.rawValue }) {
                removePendingDailyNotifications()
            }
        case .authorized, .provisional, .ephemeral:
            // Разрешения есть - проверяем запланированные уведомления
            let pendingRequests = await notificationCenter.pendingNotificationRequests()
            let hasScheduledNotification = pendingRequests.contains { request in
                request.identifier == Key.dailyWorkoutReminder.rawValue
            }
            if workoutNotificationsEnabled {
                if !hasScheduledNotification {
                    scheduleDailyNotification()
                    logger.info("Уведомления перепланированы после синхронизации")
                }
            } else if hasScheduledNotification {
                // Настройка выключена, но есть запланированные уведомления, значит
                // настройка была отключена из-за отзыва разрешений - восстанавливаем
                workoutNotificationsEnabled = true
                logger.info("Уведомления восстановлены: разрешения вернулись")
            }
        // Если настройка выключена и нет запланированных уведомлений, значит
        // настройка была отключена пользователем вручную, не восстанавливаем
        case .notDetermined:
            if workoutNotificationsEnabled {
                let granted = await checkNotificationPermissions()
                workoutNotificationsEnabled = granted
                if granted {
                    scheduleDailyNotification()
                    logger.info("Разрешения на уведомления получены, уведомления запланированы")
                } else {
                    showNotificationError = true
                    notificationError = .denied
                    logger.info("Пользователь отказал в разрешениях на уведомления")
                }
            } else {
                // Настройка выключена - убеждаемся, что уведомления не запланированы
                let pendingRequests = await notificationCenter.pendingNotificationRequests()
                if pendingRequests.contains(where: { $0.identifier == Key.dailyWorkoutReminder.rawValue }) {
                    removePendingDailyNotifications()
                }
            }
        @unknown default:
            if workoutNotificationsEnabled {
                workoutNotificationsEnabled = false
                logger.warning("Неизвестный статус разрешений на уведомления, настройка отключена")
            }
        }
    }

    func didLogout() {
        setWorkoutNotificationsEnabled(false)
        notificationCenter.removeAllPendingNotificationRequests()
    }
}

enum NotificationError: Error, LocalizedError {
    case denied

    var errorDescription: String? {
        String(localized: .errorNotificationPermission)
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
        /// Мелодия для уведомления об окончании отдыха
        case timerSound = "WorkoutTimerSound"
        /// Идентификатор для ежедневного уведомления
        case dailyWorkoutReminder
    }
}

private extension AppSettings {
    func checkNotificationPermissions() async -> Bool {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await notificationCenter.requestAuthorization(
                    options: [.alert, .sound]
                )
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
        content.title = String(localized: .notificationDailyWorkoutTitle)
        content.body = String(localized: .notificationDailyWorkoutBody)
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
        notificationCenter.add(request)
    }

    func removePendingDailyNotifications() {
        notificationCenter.removePendingNotificationRequests(
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
