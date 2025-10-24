import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    struct InfopostErrorTests {
        private typealias SUT = HTMLContentView.InfopostError
        @Test
        func fileNotFoundError() throws {
            let error = SUT.fileNotFound(filename: "test.html")
            let description = try #require(error.errorDescription)
            #expect(description == "Файл не найден: test.html")
        }

        @Test
        func htmlProcessingFailedError() throws {
            let error = SUT.htmlProcessingFailed(filename: "test.html")
            let description = try #require(error.errorDescription)
            #expect(description == "Ошибка обработки HTML: test.html")
        }

        @Test
        func resourceCopyFailedError() throws {
            let error = SUT.resourceCopyFailed
            let description = try #require(error.errorDescription)
            #expect(description == "Ошибка копирования ресурсов")
        }

        @Test
        func unknownError() throws {
            let error = SUT.unknownError
            let description = try #require(error.errorDescription)
            #expect(description == "Неизвестная ошибка")
        }
    }
}
