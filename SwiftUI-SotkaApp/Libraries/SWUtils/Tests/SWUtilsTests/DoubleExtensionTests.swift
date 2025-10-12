import SWUtils
import Testing

struct DoubleExtensionTests {
    // MARK: - formattedForUI Tests

    @Test("Форматирование Double для UI с запятой")
    func formattedForUIWithComma() {
        let value = 70.5
        let result = value.formattedForUI()
        #expect(result == "70,5")
    }

    @Test("Форматирование Double для UI с кастомным форматом")
    func formattedForUIWithCustomFormat() {
        let value = 70.567
        let result = value.formattedForUI(format: "%.2f")
        #expect(result == "70,57")
    }

    @Test("Форматирование Double для UI с целым числом")
    func formattedForUIWithWholeNumber() {
        let value = 70.0
        let result = value.formattedForUI()
        #expect(result == "70,0")
    }

    @Test("Форматирование Double для UI с отрицательным числом")
    func formattedForUIWithNegativeNumber() {
        let value: Double = -70.5
        let result = value.formattedForUI()
        #expect(result == "-70,5")
    }

    @Test("Форматирование Double для UI с нулем")
    func formattedForUIWithZero() {
        let value = 0.0
        let result = value.formattedForUI()
        #expect(result == "0,0")
    }

    @Test("Форматирование Double для UI с очень маленьким числом")
    func formattedForUIWithVerySmallNumber() {
        let value = 0.001
        let result = value.formattedForUI(format: "%.3f")
        #expect(result == "0,001")
    }

    @Test("Форматирование Double для UI с высокой точностью")
    func formattedForUIWithHighPrecision() {
        let value = 3.14159265359
        let result = value.formattedForUI(format: "%.5f")
        #expect(result == "3,14159")
    }

    // MARK: - fromUIString Tests

    @Test("Парсинг Double из строки с запятой")
    func fromUIStringWithComma() {
        let result = Double.fromUIString("70,5")
        #expect(result == 70.5)
    }

    @Test("Парсинг Double из строки с точкой")
    func fromUIStringWithDot() {
        let result = Double.fromUIString("70.5")
        #expect(result == 70.5)
    }

    @Test("Парсинг Double из строки с целым числом")
    func fromUIStringWithWholeNumber() {
        let result = Double.fromUIString("70")
        #expect(result == 70.0)
    }

    @Test("Парсинг Double из строки с отрицательным числом")
    func fromUIStringWithNegativeNumber() {
        let result = Double.fromUIString("-70,5")
        #expect(result == -70.5)
    }

    @Test("Парсинг Double из строки с нулем")
    func fromUIStringWithZero() {
        let result = Double.fromUIString("0")
        #expect(result == 0.0)
    }

    @Test("Парсинг Double из пустой строки")
    func fromUIStringWithEmptyString() {
        let result = Double.fromUIString("")
        #expect(result == nil)
    }

    @Test("Парсинг Double из невалидной строки")
    func fromUIStringWithInvalidString() {
        let result = Double.fromUIString("abc")
        #expect(result == nil)
    }

    @Test("Парсинг Double из строки с несколькими запятыми")
    func fromUIStringWithMultipleCommas() {
        let result = Double.fromUIString("70,5,3")
        #expect(result == nil)
    }

    @Test("Парсинг Double из строки с несколькими точками")
    func fromUIStringWithMultipleDots() {
        let result = Double.fromUIString("70.5.3")
        #expect(result == nil)
    }

    @Test("Парсинг Double из строки с пробелами")
    func fromUIStringWithSpaces() {
        let result = Double.fromUIString(" 70,5 ")
        #expect(result == nil) // Пробелы не поддерживаются
    }

    @Test("Парсинг Double из строки с научной нотацией")
    func fromUIStringWithScientificNotation() {
        let result = Double.fromUIString("1.5e2")
        #expect(result == 150.0)
    }

    // MARK: - Round-trip Tests

    @Test("Round-trip: Double -> UI String -> Double")
    func roundTripDoubleToUIStringToDouble() {
        let originalValue = 70.5
        let uiString = originalValue.formattedForUI()
        let parsedValue = Double.fromUIString(uiString)
        #expect(parsedValue == originalValue)
    }

    @Test("Round-trip: UI String -> Double -> UI String")
    func roundTripUIStringToDoubleToUIString() {
        let originalString = "70,5"
        let doubleValue = Double.fromUIString(originalString)
        #expect(doubleValue != nil)

        let uiString = doubleValue!.formattedForUI()
        #expect(uiString == originalString)
    }

    @Test("Round-trip с высокой точностью")
    func roundTripWithHighPrecision() {
        let originalValue = 3.14159
        let uiString = originalValue.formattedForUI(format: "%.5f")
        let parsedValue = Double.fromUIString(uiString)
        #expect(parsedValue == originalValue)
    }
}
