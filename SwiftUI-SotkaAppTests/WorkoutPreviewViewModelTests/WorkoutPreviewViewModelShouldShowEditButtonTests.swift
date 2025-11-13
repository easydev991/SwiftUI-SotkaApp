import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для shouldShowEditButton")
    struct ShouldShowEditButtonTests {
        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = cycles")
        @MainActor
        func returnsTrueForShouldShowEditButtonWhenCycles() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .cycles

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = sets")
        @MainActor
        func returnsTrueForShouldShowEditButtonWhenSets() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .sets

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать false для shouldShowEditButton когда selectedExecutionType = turbo")
        @MainActor
        func returnsFalseForShouldShowEditButtonWhenTurbo() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .turbo

            #expect(!viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать false для shouldShowEditButton когда selectedExecutionType = nil")
        @MainActor
        func returnsFalseForShouldShowEditButtonWhenNil() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = nil

            #expect(!viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = cycles и isWorkoutCompleted = true")
        @MainActor
        func returnsTrueForShouldShowEditButtonWhenCyclesAndWorkoutCompleted() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .cycles
            viewModel.isWorkoutCompleted = true

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = sets и isWorkoutCompleted = true")
        @MainActor
        func returnsTrueForShouldShowEditButtonWhenSetsAndWorkoutCompleted() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .sets
            viewModel.isWorkoutCompleted = true

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = cycles и isWorkoutCompleted = false")
        @MainActor
        func returnsTrueForShouldShowEditButtonWhenCyclesAndWorkoutNotCompleted() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .cycles
            viewModel.isWorkoutCompleted = false

            #expect(viewModel.shouldShowEditButton)
        }

        @Test("Должен возвращать true для shouldShowEditButton когда selectedExecutionType = sets и isWorkoutCompleted = false")
        @MainActor
        func returnsTrueForShouldShowEditButtonWhenSetsAndWorkoutNotCompleted() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.selectedExecutionType = .sets
            viewModel.isWorkoutCompleted = false

            #expect(viewModel.shouldShowEditButton)
        }
    }
}
