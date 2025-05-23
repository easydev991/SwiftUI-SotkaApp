import Foundation

/// Модель для обратной связи по странам/городам
enum LocationFeedback {
    case country
    case city

    var subject: String { CommonFeedback.subject }

    var body: String {
        let question: String = switch self {
        case .country:
            NSLocalizedString("Feedback.Country", comment: "")
        case .city:
            NSLocalizedString("Feedback.City", comment: "")
        }
        return """
        \(CommonFeedback.sysVersion)
        \(CommonFeedback.appVersion)
        \(question)
        \n
        """
    }
}
