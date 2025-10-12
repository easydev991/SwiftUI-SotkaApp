import Foundation

public extension Float {
    /// Форматирует Float для отображения в UI (заменяет точку на запятую)
    /// - Parameter format: Формат строки (по умолчанию "%.1f")
    /// - Returns: Отформатированная строка с запятой как разделителем
    func formattedForUI(format: String = "%.1f") -> String {
        String(format: format, self).replacingOccurrences(of: ".", with: ",")
    }

    /// Создает Float из строки, поддерживая как точку, так и запятую как разделитель
    /// - Parameter string: Строка для парсинга
    /// - Returns: Float значение или nil, если парсинг не удался
    static func fromUIString(_ string: String) -> Float? {
        let normalizedString = string.replacingOccurrences(of: ",", with: ".")
        return Float(normalizedString)
    }
}

public extension Float? {
    /// Преобразует число с плавающей точкой в строку для UI, преобразуя 0.0 в пустую строку
    /// - Returns: Строковое представление или пустая строка для 0.0
    func stringFromFloat() -> String {
        map { $0 == 0.0 ? "" : $0.formattedForUI() } ?? ""
    }
}
