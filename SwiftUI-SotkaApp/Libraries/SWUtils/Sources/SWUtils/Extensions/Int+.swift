import Foundation

public extension Int? {
    /// Преобразует целое число в строку для UI, преобразуя 0 в пустую строку
    /// - Returns: Строковое представление или пустая строка для 0
    func stringFromInt() -> String {
        map { $0 == 0 ? "" : "\($0)" } ?? ""
    }
}
