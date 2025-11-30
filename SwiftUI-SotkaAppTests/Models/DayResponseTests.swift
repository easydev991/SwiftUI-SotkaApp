import Foundation
@testable import SwiftUI_SotkaApp
import SWNetwork
import SWUtils
import Testing

@Suite("Тесты декодирования DayResponse")
struct DayResponseTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .flexibleDateDecoding
        return decoder
    }

    private func dateFromServerDateTimeSec(_ string: String) -> Date? {
        DateFormatterService.dateFromString(string, format: .serverDateTimeSec)
    }

    // MARK: - DayResponse декодирование с числовыми полями как строками

    @Test("Должен декодировать DayResponse когда id приходит как строка")
    func decodeDayResponseWithIdAsString() throws {
        let json = try #require("""
        {
            "id": "3",
            "activity_type": "0",
            "count": "5",
            "planned_count": "4",
            "execute_type": "0",
            "train_type": "1",
            "duration": "30",
            "create_date": "2024-01-01T00:00:00",
            "modify_date": "2024-01-02T00:00:00",
            "comment": "Test comment"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        let activityType = try #require(response.activityType)
        #expect(activityType == 0)
        let count = try #require(response.count)
        #expect(count == 5)
        let plannedCount = try #require(response.plannedCount)
        #expect(plannedCount == 4)
        let executeType = try #require(response.executeType)
        #expect(executeType == 0)
        let trainType = try #require(response.trainType)
        #expect(trainType == 1)
        let duration = try #require(response.duration)
        #expect(duration == 30)
        let expectedCreateDate = try #require(dateFromServerDateTimeSec("2024-01-01T00:00:00"))
        let createDate = try #require(response.createDate)
        #expect(createDate == expectedCreateDate)
        let expectedModifyDate = try #require(dateFromServerDateTimeSec("2024-01-02T00:00:00"))
        let modifyDate = try #require(response.modifyDate)
        #expect(modifyDate == expectedModifyDate)
        let comment = try #require(response.comment)
        #expect(comment == "Test comment")
    }

    @Test("Должен декодировать DayResponse когда числовые поля приходят как числа")
    func decodeDayResponseWithNumericFieldsAsNumbers() throws {
        let json = try #require("""
        {
            "id": 3,
            "activity_type": 0,
            "count": 5,
            "planned_count": 4,
            "execute_type": 0,
            "train_type": 1,
            "duration": 30
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        let activityType = try #require(response.activityType)
        #expect(activityType == 0)
        let count = try #require(response.count)
        #expect(count == 5)
        let plannedCount = try #require(response.plannedCount)
        #expect(plannedCount == 4)
        let executeType = try #require(response.executeType)
        #expect(executeType == 0)
        let trainType = try #require(response.trainType)
        #expect(trainType == 1)
        let duration = try #require(response.duration)
        #expect(duration == 30)
    }

    @Test("Должен декодировать DayResponse когда опциональные числовые поля отсутствуют")
    func decodeDayResponseWithMissingOptionalNumericFields() throws {
        let json = try #require("""
        {
            "id": "3"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        #expect(response.activityType == nil)
        #expect(response.count == nil)
        #expect(response.plannedCount == nil)
        #expect(response.executeType == nil)
        #expect(response.trainType == nil)
        #expect(response.duration == nil)
    }

    @Test("Должен декодировать DayResponse когда id приходит как число")
    func decodeDayResponseWithIdAsNumber() throws {
        let json = try #require("""
        {
            "id": 3,
            "activity_type": "0",
            "count": "5"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        let activityType = try #require(response.activityType)
        #expect(activityType == 0)
        let count = try #require(response.count)
        #expect(count == 5)
    }

    @Test("Должен выбрасывать ошибку когда id отсутствует")
    func decodeDayResponseThrowsErrorWhenIdMissing() throws {
        let json = try #require("""
        {
            "activity_type": "0"
        }
        """.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            try decoder.decode(DayResponse.self, from: json)
        }
    }

    // MARK: - DayResponse.Training декодирование с числовыми полями как строками

    @Test("Должен декодировать Training когда числовые поля приходят как строки")
    func decodeTrainingWithNumericFieldsAsStrings() throws {
        let json = try #require("""
        {
            "type_id": "1",
            "count": "5",
            "sort_order": "2"
        }
        """.data(using: .utf8))

        let training = try decoder.decode(DayResponse.Training.self, from: json)

        let typeId = try #require(training.typeId)
        #expect(typeId == 1)
        let count = try #require(training.count)
        #expect(count == 5)
        let sortOrder = try #require(training.sortOrder)
        #expect(sortOrder == 2)
    }

    @Test("Должен декодировать Training когда числовые поля приходят как числа")
    func decodeTrainingWithNumericFieldsAsNumbers() throws {
        let json = try #require("""
        {
            "type_id": 1,
            "count": 5,
            "sort_order": 2
        }
        """.data(using: .utf8))

        let training = try decoder.decode(DayResponse.Training.self, from: json)

        let typeId = try #require(training.typeId)
        #expect(typeId == 1)
        let count = try #require(training.count)
        #expect(count == 5)
        let sortOrder = try #require(training.sortOrder)
        #expect(sortOrder == 2)
    }

    @Test("Должен декодировать Training когда опциональные числовые поля отсутствуют")
    func decodeTrainingWithMissingOptionalNumericFields() throws {
        let json = try #require("""
        {
            "custom_type_id": "custom-123"
        }
        """.data(using: .utf8))

        let training = try decoder.decode(DayResponse.Training.self, from: json)

        #expect(training.typeId == nil)
        #expect(training.count == nil)
        #expect(training.sortOrder == nil)
        let customTypeId = try #require(training.customTypeId)
        #expect(customTypeId == "custom-123")
    }

    @Test("Должен декодировать DayResponse с trainings когда числовые поля приходят как строки")
    func decodeDayResponseWithTrainingsHavingNumericFieldsAsStrings() throws {
        let json = try #require("""
        {
            "id": "3",
            "trainings": [
                {
                    "type_id": "1",
                    "count": "5",
                    "sort_order": "0"
                },
                {
                    "type_id": "2",
                    "count": "10",
                    "sort_order": "1"
                }
            ]
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        let trainings = try #require(response.trainings)
        #expect(trainings.count == 2)

        let firstTraining = trainings[0]
        let firstTypeId = try #require(firstTraining.typeId)
        #expect(firstTypeId == 1)
        let firstCount = try #require(firstTraining.count)
        #expect(firstCount == 5)
        let firstSortOrder = try #require(firstTraining.sortOrder)
        #expect(firstSortOrder == 0)

        let secondTraining = trainings[1]
        let secondTypeId = try #require(secondTraining.typeId)
        #expect(secondTypeId == 2)
        let secondCount = try #require(secondTraining.count)
        #expect(secondCount == 10)
        let secondSortOrder = try #require(secondTraining.sortOrder)
        #expect(secondSortOrder == 1)
    }

    // MARK: - DayResponse декодирование дат

    @Test("Должен декодировать DayResponse когда createDate приходит в формате server date time")
    func decodeDayResponseWithCreateDateInServerDateTimeFormat() throws {
        let json = try #require("""
        {
            "id": "3",
            "create_date": "2024-01-15T10:30:00"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        let expectedDate = try #require(dateFromServerDateTimeSec("2024-01-15T10:30:00"))
        let createDate = try #require(response.createDate)
        #expect(createDate == expectedDate)
    }

    @Test("Должен декодировать DayResponse когда createDate отсутствует")
    func decodeDayResponseWithMissingCreateDate() throws {
        let json = try #require("""
        {
            "id": "3"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        #expect(response.createDate == nil)
    }

    @Test("Должен декодировать DayResponse когда createDate приходит как null")
    func decodeDayResponseWithNullCreateDate() throws {
        let json = try #require("""
        {
            "id": "3",
            "create_date": null
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        #expect(response.createDate == nil)
    }

    @Test("Должен декодировать DayResponse когда modifyDate приходит в формате server date time")
    func decodeDayResponseWithModifyDateInServerDateTimeFormat() throws {
        let json = try #require("""
        {
            "id": "3",
            "modify_date": "2024-01-16T11:00:00"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        let expectedDate = try #require(dateFromServerDateTimeSec("2024-01-16T11:00:00"))
        let modifyDate = try #require(response.modifyDate)
        #expect(modifyDate == expectedDate)
    }

    @Test("Должен декодировать DayResponse когда modifyDate отсутствует")
    func decodeDayResponseWithMissingModifyDate() throws {
        let json = try #require("""
        {
            "id": "3"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        #expect(response.modifyDate == nil)
    }

    @Test("Должен декодировать DayResponse когда modifyDate приходит как null")
    func decodeDayResponseWithNullModifyDate() throws {
        let json = try #require("""
        {
            "id": "3",
            "modify_date": null
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        #expect(response.modifyDate == nil)
    }

    @Test("Должен декодировать DayResponse когда createDate приходит как невалидная строка")
    func decodeDayResponseWithInvalidCreateDate() throws {
        let json = try #require("""
        {
            "id": "3",
            "create_date": "invalid-date"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        #expect(response.createDate == nil)
    }

    @Test("Должен декодировать DayResponse когда modifyDate приходит как невалидная строка")
    func decodeDayResponseWithInvalidModifyDate() throws {
        let json = try #require("""
        {
            "id": "3",
            "modify_date": "invalid-date"
        }
        """.data(using: .utf8))

        let response = try decoder.decode(DayResponse.self, from: json)

        #expect(response.id == 3)
        #expect(response.modifyDate == nil)
    }
}
