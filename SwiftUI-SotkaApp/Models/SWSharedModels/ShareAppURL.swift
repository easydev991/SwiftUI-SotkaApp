import Foundation

/// Модель для создания URL для шаринга приложения в App Store
struct ShareAppURL {
    let url: URL

    /// Failable инициализатор для создания URL шаринга приложения
    /// - Parameters:
    ///   - localeIdentifier: Идентификатор локали (например, "ru_RU" или "en_US")
    ///   - appId: Идентификатор приложения в App Store
    init?(localeIdentifier: String, appId: String) {
        guard !appId.isEmpty else {
            return nil
        }
        let languageCode = localeIdentifier.split(separator: "_").first == "ru" ? "ru" : "us"
        let appStoreURLString = "https://apps.apple.com/\(languageCode)/app/\(appId)"
        guard let url = URL(string: appStoreURLString) else {
            return nil
        }
        self.url = url
    }
}
