import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты параметров запроса ProgressRequest")
struct ProgressRequestTests {
    @Test("Минимальный набор параметров: только обязательные поля, nil -> \"0\"")
    func minimalParametersWithDefaults() {
        let req = ProgressRequest(
            id: 1,
            pullups: nil,
            pushups: nil,
            squats: nil,
            weight: nil,
            modifyDate: "2025-05-11T12:00:00Z"
        )

        let p = req.requestParameters

        #expect(p["id"] == "1")
        #expect(p["pullups"] == "0")
        #expect(p["pushups"] == "0")
        #expect(p["squats"] == "0")
        #expect(p["weight"] == "0.0")
        #expect(p["modify_date"] == "2025-05-11T12:00:00Z")
        #expect(p.count == 6)
    }

    @Test("Полный набор параметров: все поля заполнены")
    func fullParametersAllFields() {
        let req = ProgressRequest(
            id: 50,
            pullups: 25,
            pushups: 50,
            squats: 75,
            weight: 75.5,
            modifyDate: "2025-05-11T12:45:00+03:00"
        )

        let p = req.requestParameters

        #expect(p["id"] == "50")
        #expect(p["pullups"] == "25")
        #expect(p["pushups"] == "50")
        #expect(p["squats"] == "75")
        #expect(p["weight"] == "75.5")
        #expect(p["modify_date"] == "2025-05-11T12:45:00+03:00")
        #expect(p.count == 6)
    }

    @Test("Частичное заполнение: только некоторые опциональные поля")
    func partialParametersSomeFields() {
        let req = ProgressRequest(
            id: 100,
            pullups: 30,
            pushups: nil,
            squats: 60,
            weight: nil,
            modifyDate: "2025-05-12T10:00:00Z"
        )

        let p = req.requestParameters

        #expect(p["id"] == "100")
        #expect(p["pullups"] == "30")
        #expect(p["pushups"] == "0")
        #expect(p["squats"] == "60")
        #expect(p["weight"] == "0.0")
        #expect(p["modify_date"] == "2025-05-12T10:00:00Z")
    }

    @Test("Преобразование типов: Int и Float в String")
    func typeConversionIntAndFloatToString() {
        let req = ProgressRequest(
            id: 1,
            pullups: 0,
            pushups: 100,
            squats: -5,
            weight: 0.0,
            modifyDate: "2025-05-11T12:00:00Z"
        )

        let p = req.requestParameters

        #expect(p["id"] == "1")
        #expect(p["pullups"] == "0")
        #expect(p["pushups"] == "100")
        #expect(p["squats"] == "-5")
        #expect(p["weight"] == "0.0")
    }

    @Test("Вес с дробной частью: правильное преобразование Float")
    func weightWithDecimalPart() {
        let req = ProgressRequest(
            id: 1,
            pullups: nil,
            pushups: nil,
            squats: nil,
            weight: 75.75,
            modifyDate: "2025-05-11T12:00:00Z"
        )

        let p = req.requestParameters

        #expect(p["weight"] == "75.75")
    }

    @Test("Всегда присутствуют все ключи независимо от nil")
    func allKeysAlwaysPresent() {
        let req = ProgressRequest(
            id: 1,
            pullups: nil,
            pushups: nil,
            squats: nil,
            weight: nil,
            modifyDate: "2025-05-11T12:00:00Z"
        )

        let p = req.requestParameters

        #expect(p.keys.contains("id"))
        #expect(p.keys.contains("pullups"))
        #expect(p.keys.contains("pushups"))
        #expect(p.keys.contains("squats"))
        #expect(p.keys.contains("weight"))
        #expect(p.keys.contains("modify_date"))
        #expect(p.keys.count == 6)
    }
}
