import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllProgressTests {
    struct ProgressPhotoTypeTests {
        @Test("deleteRequestName возвращает правильные названия для DELETE запросов")
        func deleteRequestNameReturnsCorrectNamesForDeleteRequests() {
            #expect(ProgressPhotoType.front.requestName == "front")
            #expect(ProgressPhotoType.back.requestName == "back")
            #expect(ProgressPhotoType.side.requestName == "side")
        }

        @Test("Параметризированный тест deleteRequestName", arguments: [
            (ProgressPhotoType.front, "front"),
            (ProgressPhotoType.back, "back"),
            (ProgressPhotoType.side, "side")
        ])
        func deleteRequestNameParameterized(photoType: ProgressPhotoType, expectedName: String) {
            #expect(photoType.requestName == expectedName)
        }

        @Test("Параметризированный тест localizedTitle", arguments: [
            (ProgressPhotoType.front, "Фото спереди"),
            (ProgressPhotoType.back, "Фото сзади"),
            (ProgressPhotoType.side, "Фото сбоку")
        ])
        func localizedTitleParameterized(photoType: ProgressPhotoType, expectedTitle: String) {
            #expect(photoType.localizedTitle == expectedTitle)
        }

        @Test("allCases содержит типы в правильном порядке")
        func allCasesContainsTypesInCorrectOrder() {
            let allCases = ProgressPhotoType.allCases
            #expect(allCases[0] == .front)
            #expect(allCases[1] == .back)
            #expect(allCases[2] == .side)
        }
    }
}
