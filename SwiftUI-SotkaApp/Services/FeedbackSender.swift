//
//  FeedbackSender.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 04.05.2025.
//

import UIKit

enum FeedbackSender {
    /// Открывает диплинк `mailto` для создания письма
    @MainActor
    static func sendFeedback() {
        let encodedSubject = Feedback.subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "Feedback"
        let encodedBody = Feedback.body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        if let url = URL(string: "mailto:\(Feedback.recipient)?subject=\(encodedSubject)&body=\(encodedBody)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private enum Feedback {
        static let subject = "\(ProcessInfo.processInfo.processName): Обратная связь"
        static let body = """
            Версия iOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
            Версия приложения: \((Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1")
            ---
            Что можно улучшить в приложении?
            \n
        """
        static let recipient = "starker.words-01@icloud.com"
    }
}
