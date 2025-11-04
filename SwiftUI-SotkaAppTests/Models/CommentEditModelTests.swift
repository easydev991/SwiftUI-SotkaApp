@testable import SwiftUI_SotkaApp
import Testing

struct CommentEditModelTests {
    typealias SUT = CommentEditModel

    @Test("Должен возвращать false если комментария не было и текущий пустой")
    func disabledWhenNoOriginalCommentAndCurrentIsEmpty() {
        let model = SUT(initialComment: nil)
        #expect(!model.canSave(nil))
        #expect(!model.canSave(""))
    }

    @Test("Должен возвращать true если комментария не было и текущий не пустой")
    func enabledWhenNoOriginalCommentAndCurrentIsNotEmpty() {
        let model = SUT(initialComment: nil)
        #expect(model.canSave("Новый комментарий"))
        #expect(model.canSave("Test"))
    }

    @Test("Должен возвращать false если комментарий был и не изменился")
    func disabledWhenCommentWasAndNotChanged() {
        let original = "Исходный комментарий"
        let model = SUT(initialComment: original)
        #expect(!model.canSave(original))
    }

    @Test("Должен возвращать true если комментарий был и изменился")
    func enabledWhenCommentWasAndChanged() {
        let original = "Исходный комментарий"
        let model = SUT(initialComment: original)
        #expect(model.canSave("Измененный комментарий"))
        #expect(model.canSave("Другой текст"))
    }

    @Test("Должен возвращать true если комментарий был и был удален")
    func enabledWhenCommentWasAndDeleted() {
        let original = "Исходный комментарий"
        let model = SUT(initialComment: original)
        #expect(model.canSave(nil))
        #expect(model.canSave(""))
    }

    @Test("Должен возвращать false если исходный был пустой и текущий тоже пустой")
    func disabledWhenOriginalWasEmptyAndCurrentIsEmpty() {
        let model = SUT(initialComment: "")
        #expect(!model.canSave(nil))
        #expect(!model.canSave(""))
    }

    @Test("Должен возвращать true если исходный был пустой и текущий не пустой")
    func enabledWhenOriginalWasEmptyAndCurrentIsNotEmpty() {
        let model = SUT(initialComment: "")
        #expect(model.canSave("Новый комментарий"))
    }
}
