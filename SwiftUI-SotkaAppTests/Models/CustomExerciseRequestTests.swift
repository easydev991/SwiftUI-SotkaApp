import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты параметров запроса CustomExerciseRequest")
struct CustomExerciseRequestTests {
    @Test("Минимальные параметры: без modify_date, is_hidden=false по умолчанию")
    func minimalParametersWithoutModifyDate() {
        let req = CustomExerciseRequest(
            id: "uuid-1",
            name: "Отжимания",
            imageId: 2,
            createDate: "2025-05-11T12:00:00Z"
        )

        let p = req.formParameters

        #expect(p["id"] == "uuid-1")
        #expect(p["name"] == "Отжимания")
        #expect(p["image_id"] == "2")
        #expect(p["create_date"] == "2025-05-11T12:00:00Z")
        #expect(p["is_hidden"] == "false")
        #expect(p["modify_date"] == nil)
    }

    @Test("Полный набор: с modify_date и is_hidden=true")
    func fullParametersWithModifyDateAndHidden() {
        let req = CustomExerciseRequest(
            id: "uuid-2",
            name: "Подтягивания",
            imageId: 5,
            createDate: "2025-05-10T10:00:00+03:00",
            modifyDate: "2025-05-11T11:11:11+03:00",
            isHidden: true
        )

        let p = req.formParameters

        #expect(p["id"] == "uuid-2")
        #expect(p["name"] == "Подтягивания")
        #expect(p["image_id"] == "5")
        #expect(p["create_date"] == "2025-05-10T10:00:00+03:00")
        #expect(p["is_hidden"] == "true")
        #expect(p["modify_date"] == "2025-05-11T11:11:11+03:00")
    }
}
