import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты параметров запроса DayRequest")
struct DayRequestTests {
    // MARK: - Tests

    @Test("Минимальный набор параметров: только id")
    func minimalParametersOnlyId() throws {
        let req = DayRequest(
            id: 10,
            activityType: nil,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainingType: nil,
            createDate: nil,
            modifyDate: nil,
            duration: nil,
            comment: nil,
            trainings: nil
        )
        let params = req.formParameters
        #expect(params.count == 1)
        #expect(params["id"] == "10")
    }

    @Test("Добавление modify_date только при наличии")
    func modifyDateIncludedOnlyWhenPresent() throws {
        let withoutModify = DayRequest(
            id: 1,
            activityType: nil,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainingType: nil,
            createDate: nil,
            modifyDate: nil,
            duration: nil,
            comment: nil,
            trainings: nil
        )
        #expect(withoutModify.formParameters["modify_date"] == nil)

        let withModify = DayRequest(
            id: 1,
            activityType: nil,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainingType: nil,
            createDate: nil,
            modifyDate: "2025-05-11T12:00:00Z",
            duration: nil,
            comment: nil,
            trainings: nil
        )
        #expect(withModify.formParameters["modify_date"] == "2025-05-11T12:00:00Z")
    }

    @Test("Сериализация всех доступных полей")
    func serializeAllFields() throws {
        let req = DayRequest(
            id: 2,
            activityType: 0,
            count: 4,
            plannedCount: 12,
            executeType: 1,
            trainingType: 0,
            createDate: "2025-05-11T12:41:24+03:00",
            modifyDate: "2025-05-11T12:45:00+03:00",
            duration: 100,
            comment: "тест",
            trainings: []
        )

        let p = req.formParameters
        #expect(p["id"] == "2")
        #expect(p["activity_type"] == "0")
        #expect(p["count"] == "4")
        #expect(p["planned_count"] == "12")
        #expect(p["execute_type"] == "1")
        #expect(p["training_type"] == "0")
        #expect(p["create_date"] == "2025-05-11T12:41:24+03:00")
        #expect(p["modify_date"] == "2025-05-11T12:45:00+03:00")
        #expect(p["duration"] == "100")
        #expect(p["comment"] == "тест")
    }

    @Test("Тренировки: индексация и выбор ключей по типам")
    func trainingsIndexingAndTypeKeys() throws {
        let trainings: [DayRequest.Training] = [
            .init(count: 1, typeId: 0, customTypeId: nil),
            .init(count: 2, typeId: nil, customTypeId: "custom-A"),
            .init(count: 3, typeId: 3, customTypeId: "override")
        ]

        let req = DayRequest(
            id: 1,
            activityType: nil,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainingType: nil,
            createDate: nil,
            modifyDate: nil,
            duration: nil,
            comment: nil,
            trainings: trainings
        )
        let p = req.formParameters

        // index 0
        #expect(p["training[0][count]"] == "1")
        #expect(p["training[0][type_id]"] == "0")
        #expect(p["training[0][custom_type_id]"] == nil)

        // index 1
        #expect(p["training[1][count]"] == "2")
        #expect(p["training[1][custom_type_id]"] == "custom-A")
        #expect(p["training[1][type_id]"] == nil)

        // index 2 — custom перекрывает type_id
        #expect(p["training[2][count]"] == "3")
        #expect(p["training[2][custom_type_id]"] == "override")
        #expect(p["training[2][type_id]"] == nil)
    }

    @Test("Тренировки: отсутствие ключей при nil/пустом массиве")
    func trainingsKeysAbsentWhenNilOrEmpty() throws {
        let reqNil = DayRequest(
            id: 1,
            activityType: nil,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainingType: nil,
            createDate: nil,
            modifyDate: nil,
            duration: nil,
            comment: nil,
            trainings: nil
        )
        let pNil = reqNil.formParameters
        #expect(pNil.keys.first(where: { $0.hasPrefix("training[") }) == nil)

        let reqEmpty = DayRequest(
            id: 1,
            activityType: nil,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainingType: nil,
            createDate: nil,
            modifyDate: nil,
            duration: nil,
            comment: nil,
            trainings: []
        )
        let pEmpty = reqEmpty.formParameters
        #expect(pEmpty.keys.first(where: { $0.hasPrefix("training[") }) == nil)
    }
}
