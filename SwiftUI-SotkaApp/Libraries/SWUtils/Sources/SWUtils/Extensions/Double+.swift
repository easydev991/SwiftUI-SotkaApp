import Foundation

public extension Double {
    /// Форматирует Double для отображения в UI (заменяет точку на запятую)
    /// - Parameter format: Формат строки (по умолчанию "%.1f")
    /// - Returns: Отформатированная строка с запятой как разделителем
    func formattedForUI(format: String = "%.1f") -> String {
        String(format: format, self).replacingOccurrences(of: ".", with: ",")
    }

    /// Создает Double из строки, поддерживая как точку, так и запятую как разделитель
    /// - Parameter string: Строка для парсинга
    /// - Returns: Double значение или nil, если парсинг не удался
    static func fromUIString(_ string: String) -> Double? {
        let normalizedString = string.replacingOccurrences(of: ",", with: ".")
        return Double(normalizedString)
    }
}
