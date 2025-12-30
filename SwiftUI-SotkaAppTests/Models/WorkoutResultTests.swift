import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для WorkoutResult")
struct WorkoutResultTests {
    @Test("Должен сериализоваться в JSON и десериализоваться обратно")
    func serializesAndDeserializesJSON() throws {
        let result = WorkoutResult(count: 5, duration: 120)

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutResult.self, from: data)

        #expect(decoded.count == 5)
        let duration = try #require(decoded.duration)
        #expect(duration == 120)
    }

    @Test("Должен корректно обрабатывать nil значение duration")
    func handlesNilDuration() throws {
        let result = WorkoutResult(count: 3, duration: nil)

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutResult.self, from: data)

        #expect(decoded.count == 3)
        #expect(decoded.duration == nil)
    }

    @Test("Должен корректно кодировать и декодировать все поля")
    func encodesAndDecodesAllFields() throws {
        let result = WorkoutResult(count: 10, duration: 300)

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutResult.self, from: data)

        #expect(decoded.count == result.count)
        let decodedDuration = try #require(decoded.duration)
        let originalDuration = try #require(result.duration)
        #expect(decodedDuration == originalDuration)
    }

    @Test("Должен корректно декодироваться из JSON строки")
    func decodesFromJSONString() throws {
        let jsonString = """
        {
            "count": 7,
            "duration": 180
        }
        """
        let jsonData = jsonString.data(using: .utf8)
        let data = try #require(jsonData)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutResult.self, from: data)

        #expect(decoded.count == 7)
        let duration = try #require(decoded.duration)
        #expect(duration == 180)
    }

    @Test("Должен корректно декодироваться из JSON строки с null duration")
    func decodesFromJSONStringWithNullDuration() throws {
        let jsonString = """
        {
            "count": 4,
            "duration": null
        }
        """
        let jsonData = jsonString.data(using: .utf8)
        let data = try #require(jsonData)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutResult.self, from: data)

        #expect(decoded.count == 4)
        #expect(decoded.duration == nil)
    }
}
