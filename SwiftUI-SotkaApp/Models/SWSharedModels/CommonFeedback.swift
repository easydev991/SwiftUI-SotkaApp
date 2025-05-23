import Foundation

/// Модель для общей обратной связи
enum CommonFeedback {
    static let subject = "\(ProcessInfo.processInfo.processName): Обратная связь"

    static let body = """
        \(CommonFeedback.sysVersion)
        \(CommonFeedback.appVersion)
        \(CommonFeedback.question)
        \n
    """
    private static let question = NSLocalizedString(
        "Feedback.CommonQuestion",
        comment: ""
    )
    static let sysVersion = "iOS: \(ProcessInfo.processInfo.operatingSystemVersionString)"
    static let appVersion = "App version: \(Constants.appVersion)"
}
