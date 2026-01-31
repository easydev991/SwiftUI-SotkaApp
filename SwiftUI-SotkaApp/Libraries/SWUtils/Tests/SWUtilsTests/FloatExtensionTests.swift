import SWUtils
import Testing

struct FloatExtensionTests {
    // MARK: - formattedForUI Tests

    @Test("Форматирование Float для UI с запятой")
    func formattedForUIWithComma() {
        let value: Float = 70.5
        let result = value.formattedForUI()
        #expect(result == "70,5")
    }

    @Test("Форматирование Float для UI с кастомным форматом")
    func formattedForUIWithCustomFormat() {
        let value: Float = 70.567
        let result = value.formattedForUI(format: "%.2f")
        #expect(result == "70,57")
    }

    @Test("Форматирование Float для UI с целым числом")
    func formattedForUIWithWholeNumber() {
        let value: Float = 70.0
        let result = value.formattedForUI()
        #expect(result == "70,0")
    }

    @Test("Форматирование Float для UI с отрицательным числом")
    func formattedForUIWithNegativeNumber() {
        let value: Float = -70.5
        let result = value.formattedForUI()
        #expect(result == "-70,5")
    }

    @Test("Форматирование Float для UI с нулем")
    func formattedForUIWithZero() {
        let value: Float = 0.0
        let result = value.formattedForUI()
        #expect(result == "0,0")
    }

    @Test("Форматирование Float для UI с очень маленьким числом")
    func formattedForUIWithVerySmallNumber() {
        let value: Float = 0.001
        let result = value.formattedForUI(format: "%.3f")
        #expect(result == "0,001")
    }

    // MARK: - fromUIString Tests

    @Test("Парсинг Float из строки с запятой")
    func fromUIStringWithComma() {
        let result = Float.fromUIString("70,5")
        #expect(result == 70.5)
    }

    @Test("Парсинг Float из строки с точкой")
    func fromUIStringWithDot() {
        let result = Float.fromUIString("70.5")
        #expect(result == 70.5)
    }

    @Test("Парсинг Float из строки с целым числом")
    func fromUIStringWithWholeNumber() {
        let result = Float.fromUIString("70")
        #expect(result == 70.0)
    }

    @Test("Парсинг Float из строки с отрицательным числом")
    func fromUIStringWithNegativeNumber() {
        let result = Float.fromUIString("-70,5")
        #expect(result == -70.5)
    }

    @Test("Парсинг Float из строки с нулем")
    func fromUIStringWithZero() {
        let result = Float.fromUIString("0")
        #expect(result == 0.0)
    }

    @Test("Парсинг Float из пустой строки")
    func fromUIStringWithEmptyString() {
        let result = Float.fromUIString("")
        #expect(result == nil)
    }

    @Test("Парсинг Float из невалидной строки")
    func fromUIStringWithInvalidString() {
        let result = Float.fromUIString("abc")
        #expect(result == nil)
    }

    @Test("Парсинг Float из строки с несколькими запятыми")
    func fromUIStringWithMultipleCommas() {
        let result = Float.fromUIString("70,5,3")
        #expect(result == nil)
    }

    @Test("Парсинг Float из строки с несколькими точками")
    func fromUIStringWithMultipleDots() {
        let result = Float.fromUIString("70.5.3")
        #expect(result == nil)
    }

    @Test("Парсинг Float из строки с пробелами")
    func fromUIStringWithSpaces() {
        let result = Float.fromUIString(" 70,5 ")
        #expect(result == nil) // Пробелы не поддерживаются
    }

    // MARK: - Round-trip Tests

    @Test("Round-trip: Float -> UI String -> Float")
    func roundTripFloatToUIStringToFloat() {
        let originalValue: Float = 70.5
        let uiString = originalValue.formattedForUI()
        let parsedValue = Float.fromUIString(uiString)
        #expect(parsedValue == originalValue)
    }

    @Test("Round-trip: UI String -> Float -> UI String")
    func roundTripUIStringToFloatToUIString() throws {
        let originalString = "70,5"
        let floatValue = Float.fromUIString(originalString)
        #expect(floatValue != nil)

        let uiString = try #require(floatValue?.formattedForUI())
        #expect(uiString == originalString)
    }

    // MARK: - stringFromFloat Tests

    @Test("stringFromFloat с положительным числом")
    func stringFromFloatWithPositiveNumber() {
        let value: Float? = 70.5
        let result = value.stringFromFloat()
        #expect(result == "70,5")
    }

    @Test("stringFromFloat с нулем")
    func stringFromFloatWithZero() {
        let value: Float? = 0.0
        let result = value.stringFromFloat()
        #expect(result == "")
    }

    @Test("stringFromFloat с nil")
    func stringFromFloatWithNil() {
        let value: Float? = nil
        let result = value.stringFromFloat()
        #expect(result == "")
    }

    @Test("stringFromFloat с отрицательным числом")
    func stringFromFloatWithNegativeNumber() {
        let value: Float? = -70.5
        let result = value.stringFromFloat()
        #expect(result == "-70,5")
    }

    @Test("stringFromFloat с целым числом")
    func stringFromFloatWithWholeNumber() {
        let value: Float? = 70.0
        let result = value.stringFromFloat()
        #expect(result == "70,0")
    }
}
