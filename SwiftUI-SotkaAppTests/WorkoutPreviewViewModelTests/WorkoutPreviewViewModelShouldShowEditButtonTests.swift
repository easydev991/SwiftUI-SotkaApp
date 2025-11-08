import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutPreviewViewModelTests {
    // MARK: - shouldShowEditButton Tests

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
}
