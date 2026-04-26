import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для shouldShowEditButton")
    @MainActor
    struct ShouldShowEditButtonTests {
        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = cycles")
        func returnsTrueForShouldShowEditButtonWhenCycles() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .cycles

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = sets")
        func returnsTrueForShouldShowEditButtonWhenSets() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .sets

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать false для shouldShowEditButton когда selectedExecutionType = turbo")
        func returnsFalseForShouldShowEditButtonWhenTurbo() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .turbo

            #expect(!viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать false для shouldShowEditButton когда selectedExecutionType = nil")
        func returnsFalseForShouldShowEditButtonWhenNil() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = nil

            #expect(!viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = cycles и isWorkoutCompleted = true")
        func returnsTrueForShouldShowEditButtonWhenCyclesAndWorkoutCompleted() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .cycles
            viewModel.isWorkoutCompleted = true

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = sets и isWorkoutCompleted = true")
        func returnsTrueForShouldShowEditButtonWhenSetsAndWorkoutCompleted() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .sets
            viewModel.isWorkoutCompleted = true

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = cycles и isWorkoutCompleted = false")
        func returnsTrueForShouldShowEditButtonWhenCyclesAndWorkoutNotCompleted() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .cycles
            viewModel.isWorkoutCompleted = false

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = sets и isWorkoutCompleted = false")
        func returnsTrueForShouldShowEditButtonWhenSetsAndWorkoutNotCompleted() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .sets
            viewModel.isWorkoutCompleted = false

            #expect(viewModel.shouldShowEditButton)
        }
    }
}
