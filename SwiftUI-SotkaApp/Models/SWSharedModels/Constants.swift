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
