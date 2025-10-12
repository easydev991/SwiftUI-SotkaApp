import SWUtils
import Testing

struct IntExtensionTests {
    // MARK: - stringFromInt Tests

    @Test("stringFromInt с положительным числом")
    func stringFromIntWithPositiveNumber() {
        let value: Int? = 70
        let result = value.stringFromInt()
        #expect(result == "70")
    }

    @Test("stringFromInt с нулем")
    func stringFromIntWithZero() {
        let value: Int? = 0
        let result = value.stringFromInt()
        #expect(result == "")
    }

    @Test("stringFromInt с nil")
    func stringFromIntWithNil() {
        let value: Int? = nil
        let result = value.stringFromInt()
        #expect(result == "")
    }

    @Test("stringFromInt с отрицательным числом")
    func stringFromIntWithNegativeNumber() {
        let value: Int? = -70
        let result = value.stringFromInt()
        #expect(result == "-70")
    }

    @Test("stringFromInt с большим числом")
    func stringFromIntWithLargeNumber() {
        let value: Int? = 1000
        let result = value.stringFromInt()
        #expect(result == "1000")
    }

    @Test("stringFromInt с максимальным значением")
    func stringFromIntWithMaxValue() {
        let value: Int? = Int.max
        let result = value.stringFromInt()
        #expect(result == "\(Int.max)")
    }

    @Test("stringFromInt с минимальным значением")
    func stringFromIntWithMinValue() {
        let value: Int? = Int.min
        let result = value.stringFromInt()
        #expect(result == "\(Int.min)")
    }
}
