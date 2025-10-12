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

    /// Проверяет, является ли строка валидным неотрицательным целым числом (0 или положительное)
    /// - Returns: true, если строка пустая или содержит неотрицательное целое число (>= 0)
    var isValidNonNegativeInteger: Bool {
        guard !isEmpty else { return true }
        guard let value = Int(self) else { return false }
        return value >= 0
    }

    /// Проверяет, является ли строка валидным неотрицательным числом с плавающей точкой (0 или положительное)
    /// - Returns: true, если строка пустая или содержит неотрицательное число с плавающей точкой (>= 0)
    var isValidNonNegativeFloat: Bool {
        guard !isEmpty else { return true }
        // Используем утилиту для парсинга Float из UI строки
        guard let value = Float.fromUIString(self) else { return false }
        return value >= 0
    }
}

public extension String? {
    /// `URL` без кириллицы
    var queryAllowedURL: URL? {
        guard let self else { return nil }
        return .init(string: self, encodingInvalidCharacters: true)
    }
}
