import Foundation

enum Constants {
    /// Минимальная длина пароля
    static let minPasswordSize = 6
    static let defaultRestTime = 60
    static let restPickerOptions: [Int] = Array(stride(from: 5, through: 600, by: 5))
    /// Минимальный возраст пользователя (13 лет)
    static let minUserAge = Calendar.current.date(byAdding: .year, value: -13, to: .now) ?? .now
    static let appVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "4.0.0"
    /// Получатели обратной связи
    static let feedbackRecipients = ["info@workout.su", "cuties.84tilbury@icloud.com"]
}

extension Constants {
    static let appId = "id6753644091"
    static let appReviewURL = URL(string: "https://apps.apple.com/app/\(Constants.appId)?action=write-review")
    static let workoutSuURL = URL(string: "https://workout.su")
    static let swParksAppURL = URL(string: "https://apps.apple.com/app/id6749501617")
    static let workoutShopURL = URL(string: "https://workoutshop.ru/?utm_source=iOS&utm_medium=100&utm_campaign=NASTROIKI")
    static let githubPageURL = URL(string: "https://github.com/easydev991/SwiftUI-SotkaApp")
}

extension Constants {
    /// Ключ для статуса авторизации в UserDefaults
    static let isAuthorizedKey = "isAuthorized"
    /// Ключ для даты начала программы в UserDefaults
    static let startDateKey = "WorkoutStartDate"
    /// Ключ для времени отдыха между подходами/кругами в секундах
    ///
    /// Значение взял из старого приложения
    static let restTimeKey = "WorkoutTimer"
}

extension Constants {
    /// Команды для обмена данными между часами и `iPhone` через `WatchConnectivity`
    enum WatchCommand: String {
        // От часов к iPhone
        case setActivity = "WATCH_COMMAND_SET_ACTIVITY"
        case saveWorkout = "WATCH_COMMAND_SAVE_WORKOUT"
        case getCurrentActivity = "WATCH_COMMAND_GET_CURRENT_ACTIVITY"
        case getWorkoutData = "WATCH_COMMAND_GET_WORKOUT_DATA"
        case deleteActivity = "WATCH_COMMAND_DELETE_ACTIVITY"

        // От iPhone к часам
        case currentActivity = "PHONE_COMMAND_CURRENT_ACTIVITY"
        case sendWorkoutData = "PHONE_COMMAND_SEND_WORKOUT_DATA"
        case authStatus = "PHONE_COMMAND_AUTH_STATUS"
        case currentDay = "PHONE_COMMAND_CURRENT_DAY"
    }
}
