@testable import SwiftUI_SotkaApp
import Testing

struct AddCustomExerciseModelTests {
    typealias SUT = EditCustomExerciseScreen.Model

    @Test("Нельзя сохранить с пустым именем", arguments: ["", "   ", "  \n  "])
    func cannotSaveWhenNameIsEmpty(name: String) {
        var model = SUT()
        model.exerciseName = name
        model.selectedImageId = 1
        #expect(!model.canSaveExercise)
    }

    @Test("Нельзя сохранить без выбранной иконки")
    func cannotSaveWhenIconNotSelected() {
        var model = SUT()
        model.exerciseName = "Отжимания"
        model.selectedImageId = -1
        #expect(!model.canSaveExercise)
    }

    @Test("Можно сохранить с валидными данными")
    func canSaveWhenValidData() {
        var model = SUT()
        model.exerciseName = "Отжимания"
        model.selectedImageId = 2
        #expect(model.canSaveExercise)
    }
}
