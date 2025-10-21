import SWUtils
import Testing

struct StringExtensionTests {
    // MARK: - isValidNonNegativeInteger Tests

    @Test("isValidNonNegativeInteger с валидными значениями", arguments: ["", "0", "70", "1000000"])
    func isValidNonNegativeIntegerWithValidValues(input: String) {
        let result = input.isValidNonNegativeInteger
        #expect(result)
    }

    @Test("isValidNonNegativeInteger с невалидными значениями", arguments: ["-70", "abc", "70.5", "70,5", " 70 "])
    func isValidNonNegativeIntegerWithInvalidValues(input: String) {
        let result = input.isValidNonNegativeInteger
        #expect(!result)
    }

    // MARK: - isValidNonNegativeFloat Tests

    @Test(
        "isValidNonNegativeFloat с валидными значениями",
        arguments: ["", "0", "0.0", "0,0", "70.5", "70,5", "0.001", "0,001", "1000000.5", "1000000,5"]
    )
    func isValidNonNegativeFloatWithValidValues(input: String) {
        let result = input.isValidNonNegativeFloat
        #expect(result)
    }

    @Test("isValidNonNegativeFloat с невалидными значениями", arguments: ["-70.5", "-70,5", "abc", " 70.5 ", "70.5.3", "70,5,3"])
    func isValidNonNegativeFloatWithInvalidValues(input: String) {
        let result = input.isValidNonNegativeFloat
        #expect(!result)
    }
}
