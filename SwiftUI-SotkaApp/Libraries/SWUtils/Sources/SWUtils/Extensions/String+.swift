import Foundation

public extension String {
    var capitalizingFirstLetter: String {
        prefix(1).capitalized + dropFirst()
    }

    /// Количество символов без учета пробелов
    var trueCount: Int { withoutSpaces.count }

    /// Без пробелов
    var withoutSpaces: Self {
        replacingOccurrences(of: " ", with: "")
    }
}

public extension String? {
    /// `URL` без кириллицы
    var queryAllowedURL: URL? {
        guard let self else { return nil }
        return .init(string: self, encodingInvalidCharacters: true)
    }
}
