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
