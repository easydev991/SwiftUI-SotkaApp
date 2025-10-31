import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

@Suite("Тесты для ExerciseSnapshot")
struct ExerciseSnapshotTests {
    // MARK: - exerciseRequest Tests

    @Test("exerciseRequest корректно преобразует все поля в CustomExerciseRequest")
    func exerciseRequestWithAllFields() throws {
        let createDate = Date(timeIntervalSince1970: 1700000000)
        let modifyDate = Date(timeIntervalSince1970: 1700100000)

        let snapshot = ExerciseSnapshot(
            id: "exercise-1",
            name: "Отжимания",
            imageId: 5,
            createDate: createDate,
            modifyDate: modifyDate,
            isSynced: true,
            shouldDelete: false,
            userId: 123
        )

        let request = snapshot.exerciseRequest

        #expect(request.id == "exercise-1")
        #expect(request.name == "Отжимания")
        #expect(request.imageId == 5)
        #expect(request.createDate == DateFormatterService.stringFromFullDate(createDate, format: .isoDateTimeSec))
        let modifyDateStr = try #require(request.modifyDate)
        #expect(modifyDateStr == DateFormatterService.stringFromFullDate(modifyDate, format: .isoDateTimeSec))
        #expect(request.isHidden == false)
    }

    @Test("exerciseRequest устанавливает isHidden в false")
    func exerciseRequestSetsIsHiddenToFalse() {
        let snapshot = ExerciseSnapshot(
            id: "exercise-2",
            name: "Подтягивания",
            imageId: 3,
            createDate: Date(),
            modifyDate: Date(),
            isSynced: false,
            shouldDelete: false,
            userId: nil
        )

        let request = snapshot.exerciseRequest

        #expect(!request.isHidden)
    }

    @Test("exerciseRequest корректно форматирует даты в ISO формат")
    func exerciseRequestFormatsDatesCorrectly() throws {
        let createDate = Date(timeIntervalSince1970: 1700000000)
        let modifyDate = Date(timeIntervalSince1970: 1700100000)

        let snapshot = ExerciseSnapshot(
            id: "exercise-3",
            name: "Приседания",
            imageId: 7,
            createDate: createDate,
            modifyDate: modifyDate,
            isSynced: true,
            shouldDelete: false,
            userId: 456
        )

        let request = snapshot.exerciseRequest

        let expectedCreateDate = DateFormatterService.stringFromFullDate(createDate, format: .isoDateTimeSec)
        let expectedModifyDate = DateFormatterService.stringFromFullDate(modifyDate, format: .isoDateTimeSec)

        #expect(request.createDate == expectedCreateDate)
        let modifyDateStr = try #require(request.modifyDate)
        #expect(modifyDateStr == expectedModifyDate)
    }

    @Test("exerciseRequest не зависит от флагов isSynced и shouldDelete")
    func exerciseRequestIndependentOfSyncFlags() {
        let snapshot1 = ExerciseSnapshot(
            id: "exercise-4",
            name: "Выпады",
            imageId: 9,
            createDate: Date(),
            modifyDate: Date(),
            isSynced: true,
            shouldDelete: false,
            userId: nil
        )

        let snapshot2 = ExerciseSnapshot(
            id: "exercise-4",
            name: "Выпады",
            imageId: 9,
            createDate: snapshot1.createDate,
            modifyDate: snapshot1.modifyDate,
            isSynced: false,
            shouldDelete: true,
            userId: nil
        )

        let request1 = snapshot1.exerciseRequest
        let request2 = snapshot2.exerciseRequest

        #expect(request1.id == request2.id)
        #expect(request1.name == request2.name)
        #expect(request1.imageId == request2.imageId)
        #expect(request1.createDate == request2.createDate)
        #expect(request1.isHidden == request2.isHidden)
    }
}
