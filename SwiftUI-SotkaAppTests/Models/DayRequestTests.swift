import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты параметров запроса DayRequest")
struct DayRequestTests {
    // MARK: - Tests

    @Test("Минимальный набор параметров: только id")
    func minimalParametersOnlyId() {
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
    func modifyDateIncludedOnlyWhenPresent() {
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
    func serializeAllFields() {
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
    func trainingsIndexingAndTypeKeys() {
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
    func trainingsKeysAbsentWhenNilOrEmpty() {
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

    @Test("DayRequest.Training должен содержать поле sortOrder")
    func trainingShouldContainSortOrder() throws {
        let training = DayRequest.Training(
            count: 10,
            typeId: 1,
            customTypeId: nil,
            sortOrder: 5
        )
        let sortOrder = try #require(training.sortOrder)
        #expect(sortOrder == 5)
    }

    @Test("ActivitySnapshot.dayRequest должен передавать sortOrder из TrainingSnapshot в DayRequest.Training")
    func activitySnapshotDayRequestShouldPassSortOrder() throws {
        let snapshot = ActivitySnapshot(
            day: 3,
            activityTypeRaw: nil,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: Date(),
            modifyDate: Date(),
            isSynced: false,
            shouldDelete: false,
            userId: nil,
            trainings: [
                ActivitySnapshot.TrainingSnapshot(
                    count: 10,
                    typeId: 1,
                    customTypeId: nil,
                    sortOrder: 2
                )
            ]
        )
        let dayRequest = snapshot.dayRequest
        let training = try #require(dayRequest.trainings?.first)
        let sortOrder = try #require(training.sortOrder)
        #expect(sortOrder == 2)
    }

    @Test("DayRequest.formParameters должен включать training[index][sort_order] для каждой тренировки")
    func formParametersShouldIncludeSortOrder() {
        let trainings: [DayRequest.Training] = [
            .init(count: 1, typeId: 0, customTypeId: nil, sortOrder: 0),
            .init(count: 2, typeId: 1, customTypeId: nil, sortOrder: 1),
            .init(count: 3, typeId: 2, customTypeId: nil, sortOrder: 2)
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

        #expect(p["training[0][sort_order]"] == "0")
        #expect(p["training[1][sort_order]"] == "1")
        #expect(p["training[2][sort_order]"] == "2")
    }

    @Test("sort_order должен быть равен индексу в массиве, если не указан явно")
    func sortOrderShouldEqualIndexWhenNotSpecified() {
        let trainings: [DayRequest.Training] = [
            .init(count: 1, typeId: 0, customTypeId: nil, sortOrder: nil),
            .init(count: 2, typeId: 1, customTypeId: nil, sortOrder: nil),
            .init(count: 3, typeId: 2, customTypeId: nil, sortOrder: nil)
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

        #expect(p["training[0][sort_order]"] == "0")
        #expect(p["training[1][sort_order]"] == "1")
        #expect(p["training[2][sort_order]"] == "2")
    }

    @Test("Тренировки должны быть отсортированы по sortOrder перед отправкой, индекс массива должен соответствовать sort_order")
    func trainingsShouldBeSortedBySortOrder() {
        let trainings: [DayRequest.Training] = [
            .init(count: 1, typeId: 0, customTypeId: nil, sortOrder: 2),
            .init(count: 2, typeId: 1, customTypeId: nil, sortOrder: 0),
            .init(count: 3, typeId: 2, customTypeId: nil, sortOrder: 1)
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

        // После сортировки training[0] должен иметь sort_order=0 (typeId=1)
        #expect(p["training[0][sort_order]"] == "0")
        #expect(p["training[0][type_id]"] == "1")
        // training[1] должен иметь sort_order=1 (typeId=2)
        #expect(p["training[1][sort_order]"] == "1")
        #expect(p["training[1][type_id]"] == "2")
        // training[2] должен иметь sort_order=2 (typeId=0)
        #expect(p["training[2][sort_order]"] == "2")
        #expect(p["training[2][type_id]"] == "0")
    }
}
