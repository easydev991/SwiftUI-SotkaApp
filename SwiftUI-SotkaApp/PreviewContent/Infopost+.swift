#if DEBUG
import Foundation

extension Infopost {
    static let preview = Self(
        id: "d2",
        title: "День 2. Демо-статья",
        content: "<html><body><h1>Заголовок статьи</h1><p>Контент статьи...</p></body></html>",
        section: .base,
        dayNumber: 2,
        language: "ru"
    )
}
#endif
