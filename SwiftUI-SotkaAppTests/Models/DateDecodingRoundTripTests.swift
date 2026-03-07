import Foundation
import SWNetwork
import SWUtils
import Testing

@Suite("Тесты round-trip для декодирования дат")
struct DateDecodingRoundTripTests {
    private struct TestModel: Decodable {
        let date: Date
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .flexibleDateDecoding
        return decoder
    }

    @Test("Timezone-less server datetime после декодирования сериализуется в исходящий UTC wire-format")
    func decodeServerDateTimeRoundTripToOutgoingUTC() throws {
        let date = try decodeDate("2024-01-15T10:30:00")
        let result = DateFormatterService.stringFromFullDate(date, iso: true)
        #expect(result == "2024-01-15T07:30:00.000Z")
    }

    private func decodeDate(_ value: String) throws -> Date {
        let json = try #require("""
        {
            "date": "\(value)"
        }
        """.data(using: .utf8))

        return try decoder.decode(TestModel.self, from: json).date
    }
}
