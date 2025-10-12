import SWUtils
import Testing

struct StringExtensionTests {
    // MARK: - isValidNonNegativeInteger Tests

    @Test("isValidNonNegativeInteger с пустой строкой")
    func isValidNonNegativeIntegerWithEmptyString() {
        let result = "".isValidNonNegativeInteger
        #expect(result == true)
    }

    @Test("isValidNonNegativeInteger с положительным числом")
    func isValidNonNegativeIntegerWithPositiveNumber() {
        let result = "70".isValidNonNegativeInteger
        #expect(result == true)
    }

    @Test("isValidNonNegativeInteger с нулем")
    func isValidNonNegativeIntegerWithZero() {
        let result = "0".isValidNonNegativeInteger
        #expect(result == true)
    }

    @Test("isValidNonNegativeInteger с отрицательным числом")
    func isValidNonNegativeIntegerWithNegativeNumber() {
        let result = "-70".isValidNonNegativeInteger
        #expect(result == false)
    }

    @Test("isValidNonNegativeInteger с невалидной строкой")
    func isValidNonNegativeIntegerWithInvalidString() {
        let result = "abc".isValidNonNegativeInteger
        #expect(result == false)
    }

    @Test("isValidNonNegativeInteger с числом с плавающей точкой")
    func isValidNonNegativeIntegerWithFloat() {
        let result = "70.5".isValidNonNegativeInteger
        #expect(result == false)
    }

    @Test("isValidNonNegativeInteger с числом с запятой")
    func isValidNonNegativeIntegerWithComma() {
        let result = "70,5".isValidNonNegativeInteger
        #expect(result == false)
    }

    @Test("isValidNonNegativeInteger с пробелами")
    func isValidNonNegativeIntegerWithSpaces() {
        let result = " 70 ".isValidNonNegativeInteger
        #expect(result == false)
    }

    @Test("isValidNonNegativeInteger с большим числом")
    func isValidNonNegativeIntegerWithLargeNumber() {
        let result = "1000000".isValidNonNegativeInteger
        #expect(result == true)
    }

    // MARK: - isValidNonNegativeFloat Tests

    @Test("isValidNonNegativeFloat с пустой строкой")
    func isValidNonNegativeFloatWithEmptyString() {
        let result = "".isValidNonNegativeFloat
        #expect(result == true)
    }

    @Test("isValidNonNegativeFloat с положительным числом с точкой")
    func isValidNonNegativeFloatWithPositiveNumberDot() {
        let result = "70.5".isValidNonNegativeFloat
        #expect(result == true)
    }

    @Test("isValidNonNegativeFloat с положительным числом с запятой")
    func isValidNonNegativeFloatWithPositiveNumberComma() {
        let result = "70,5".isValidNonNegativeFloat
        #expect(result == true)
    }

    @Test("isValidNonNegativeFloat с нулем")
    func isValidNonNegativeFloatWithZero() {
        let result = "0".isValidNonNegativeFloat
        #expect(result == true)
    }

    @Test("isValidNonNegativeFloat с нулем с плавающей точкой")
    func isValidNonNegativeFloatWithZeroFloat() {
        let result = "0.0".isValidNonNegativeFloat
        #expect(result == true)
    }

    @Test("isValidNonNegativeFloat с нулем с запятой")
    func isValidNonNegativeFloatWithZeroComma() {
        let result = "0,0".isValidNonNegativeFloat
        #expect(result == true)
    }

    @Test("isValidNonNegativeFloat с отрицательным числом")
    func isValidNonNegativeFloatWithNegativeNumber() {
        let result = "-70.5".isValidNonNegativeFloat
        #expect(result == false)
    }

    @Test("isValidNonNegativeFloat с отрицательным числом с запятой")
    func isValidNonNegativeFloatWithNegativeNumberComma() {
        let result = "-70,5".isValidNonNegativeFloat
        #expect(result == false)
    }

    @Test("isValidNonNegativeFloat с невалидной строкой")
    func isValidNonNegativeFloatWithInvalidString() {
        let result = "abc".isValidNonNegativeFloat
        #expect(result == false)
    }

    @Test("isValidNonNegativeFloat с пробелами")
    func isValidNonNegativeFloatWithSpaces() {
        let result = " 70.5 ".isValidNonNegativeFloat
        #expect(result == false)
    }

    @Test("isValidNonNegativeFloat с несколькими точками")
    func isValidNonNegativeFloatWithMultipleDots() {
        let result = "70.5.3".isValidNonNegativeFloat
        #expect(result == false)
    }

    @Test("isValidNonNegativeFloat с несколькими запятыми")
    func isValidNonNegativeFloatWithMultipleCommas() {
        let result = "70,5,3".isValidNonNegativeFloat
        #expect(result == false)
    }

    @Test("isValidNonNegativeFloat с очень маленьким числом")
    func isValidNonNegativeFloatWithVerySmallNumber() {
        let result = "0.001".isValidNonNegativeFloat
        #expect(result == true)
    }

    @Test("isValidNonNegativeFloat с очень маленьким числом с запятой")
    func isValidNonNegativeFloatWithVerySmallNumberComma() {
        let result = "0,001".isValidNonNegativeFloat
        #expect(result == true)
    }

    @Test("isValidNonNegativeFloat с большим числом")
    func isValidNonNegativeFloatWithLargeNumber() {
        let result = "1000000.5".isValidNonNegativeFloat
        #expect(result == true)
    }

    @Test("isValidNonNegativeFloat с большим числом с запятой")
    func isValidNonNegativeFloatWithLargeNumberComma() {
        let result = "1000000,5".isValidNonNegativeFloat
        #expect(result == true)
    }
}
