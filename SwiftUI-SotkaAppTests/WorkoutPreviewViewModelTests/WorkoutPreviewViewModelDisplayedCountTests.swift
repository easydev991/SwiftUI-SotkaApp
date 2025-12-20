import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для displayedCount")
    struct DisplayedCountTests {
        @Test("Должен возвращать count когда оба установлены (приоритет у count для сохраненных тренировок)")
        @MainActor
        func returnsCountWhenBothAreSet() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = 5
            viewModel.plannedCount = 3

            let displayedCount = try #require(viewModel.displayedCount)
            #expect(displayedCount == 5)
        }

        @Test("Должен возвращать plannedCount когда count == nil (непройденная тренировка)")
        @MainActor
        func returnsPlannedCountWhenCountIsNil() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = nil
            viewModel.plannedCount = 4

            let displayedCount = try #require(viewModel.displayedCount)
            #expect(displayedCount == 4)
        }

        @Test("Должен возвращать nil когда оба count и plannedCount равны nil")
        @MainActor
        func returnsNilWhenBothAreNil() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = nil
            viewModel.plannedCount = nil

            #expect(viewModel.displayedCount == nil)
        }

        @Test("Должен возвращать count когда plannedCount == nil (сохраненная тренировка)")
        @MainActor
        func returnsCountWhenPlannedCountIsNil() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.count = 10
            viewModel.plannedCount = nil

            let displayedCount = try #require(viewModel.displayedCount)
            #expect(displayedCount == 10)
        }
    }
}
