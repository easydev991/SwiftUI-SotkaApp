@testable import SwiftUI_SotkaApp
import Testing

struct AddCustomExerciseModelTests {
    typealias SUT = AddCustomExerciseScreen.Model

    @Test(arguments: ["", "   ", "  \n  "])
    func cannotSaveWhenNameIsEmpty(name: String) {
        var model = SUT()
        model.exerciseName = name
        model.selectedImageId = 1
        #expect(!model.canSaveExercise)
    }

    @Test
    func cannotSaveWhenIconNotSelected() {
        var model = SUT()
        model.exerciseName = "Отжимания"
        model.selectedImageId = -1
        #expect(!model.canSaveExercise)
    }

    @Test
    func cannotSaveWhenDuplicateExists() throws {
        let existing = CustomExercise(
            id: "1",
            name: "Отжимания",
            imageId: 2,
            createDate: .now,
            modifyDate: .now
        )
        var model = SUT()
        model.exerciseName = "Отжимания"
        model.selectedImageId = 2
        model.allExercises = [existing]
        #expect(model.isDuplicate)
        #expect(!model.canSaveExercise)
    }

    @Test
    func canSaveWhenNoDuplicateAndValid() {
        let existing = CustomExercise(
            id: "1",
            name: "Приседания",
            imageId: 3,
            createDate: .now,
            modifyDate: .now
        )
        var model = SUT()
        model.exerciseName = "Отжимания"
        model.selectedImageId = 2
        model.allExercises = [existing]
        #expect(!model.isDuplicate)
        #expect(model.canSaveExercise)
    }

    @Test
    func newExercisePreservesOriginalName() throws {
        var model = SUT()
        model.exerciseName = "  Отжимания  "
        model.selectedImageId = 5
        let newExercise = model.newExercise
        try #require(newExercise.name == "  Отжимания  ")
        #expect(newExercise.imageId == 5)
    }
}
