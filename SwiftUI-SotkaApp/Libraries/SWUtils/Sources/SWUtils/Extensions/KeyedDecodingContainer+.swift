import Foundation

public extension KeyedDecodingContainer {
    /// Декодирует опциональное значение Int из строки или числа
    /// - Parameter key: Ключ для декодирования
    /// - Returns: Опциональное значение Int, или nil если ключ отсутствует или значение не может быть конвертировано
    func decodeIntOrStringIfPresent(_ key: Key) -> Int? {
        if let stringValue = try? decodeIfPresent(String.self, forKey: key),
           let intValue = Int(stringValue) {
            return intValue
        } else if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        return nil
    }

    /// Декодирует обязательное значение Int из строки или числа
    /// - Parameter key: Ключ для декодирования
    /// - Returns: Значение Int
    /// - Throws: DecodingError если значение отсутствует или не может быть конвертировано
    func decodeIntOrString(_ key: Key) throws -> Int {
        if let idString = try? decodeIfPresent(String.self, forKey: key),
           let idInt = Int(idString) {
            return idInt
        } else if let idInt = try? decodeIfPresent(Int.self, forKey: key) {
            return idInt
        } else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Ожидали Int или String для конвертации в Int"
            ))
        }
    }

    /// Декодирует опциональное значение Float из строки или числа
    /// - Parameter key: Ключ для декодирования
    /// - Returns: Опциональное значение Float, или nil если ключ отсутствует или значение не может быть конвертировано
    func decodeFloatOrStringIfPresent(_ key: Key) -> Float? {
        if let stringValue = try? decodeIfPresent(String.self, forKey: key),
           let floatValue = Float(stringValue) {
            return floatValue
        } else if let floatValue = try? decodeIfPresent(Float.self, forKey: key) {
            return floatValue
        }
        return nil
    }

    /// Декодирует обязательное значение Float из строки или числа
    /// - Parameter key: Ключ для декодирования
    /// - Returns: Значение Float
    /// - Throws: DecodingError если значение отсутствует или не может быть конвертировано
    func decodeFloatOrString(_ key: Key) throws -> Float {
        if let stringValue = try? decodeIfPresent(String.self, forKey: key),
           let floatValue = Float(stringValue) {
            return floatValue
        } else if let floatValue = try? decodeIfPresent(Float.self, forKey: key) {
            return floatValue
        } else {
            throw DecodingError.typeMismatch(Float.self, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Ожидали Float или String для конвертации в Float"
            ))
        }
    }

    /// Декодирует опциональное значение Date из ISO8601 строки
    /// - Parameter key: Ключ для декодирования
    /// - Returns: Опциональное значение Date, или nil если ключ отсутствует, значение null или не может быть конвертировано
    /// - Note: Поддерживает ISO8601 формат с дробными секундами и без них
    func decodeISO8601DateIfPresent(_ key: Key) -> Date? {
        guard contains(key) else {
            return nil
        }
        guard !((try? decodeNil(forKey: key)) ?? false) else {
            return nil
        }
        guard let dateString = try? decode(String.self, forKey: key) else {
            return nil
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    /// Декодирует опциональное значение Int, обрабатывая случаи когда сервер возвращает false вместо числа
    /// - Parameter key: Ключ для декодирования
    /// - Returns: Опциональное значение Int, или nil если ключ отсутствует, значение null, false или не может быть конвертировано
    /// - Note: Обрабатывает баг на сервере, когда getUserMaxDay() может вернуть false
    func decodeIntOrNilIfPresent(_ key: Key) -> Int? {
        guard contains(key) else {
            return nil
        }
        guard !((try? decodeNil(forKey: key)) ?? false) else {
            return nil
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        }
        return nil
    }
}
