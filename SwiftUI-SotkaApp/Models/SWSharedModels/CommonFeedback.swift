import Foundation

/// Модель для общей обратной связи
enum CommonFeedback {
    static let subject = "\(ProcessInfo.processInfo.processName): Обратная связь"
    private static let question = NSLocalizedString(
        "Feedback.CommonQuestion",
        comment: ""
    )
    static let sysVersion = "iOS: \(ProcessInfo.processInfo.operatingSystemVersionString)"
    static let appVersion = "App version: \(Constants.appVersion)"
    static func makeBody(for text: String?) -> String {
        """
            \(CommonFeedback.sysVersion)
            \(CommonFeedback.appVersion)
            \(text ?? CommonFeedback.question)
            \n
        """
    }
}
