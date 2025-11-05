import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutPreviewViewModelTests {
    // MARK: - displayExecutionType Tests

    @Test("Должен возвращать cycles для turbo")
    @MainActor
    func returnsCyclesForTurbo() {
        let viewModel = WorkoutPreviewViewModel()
        let result = viewModel.displayExecutionType(for: .turbo)
        #expect(result == .cycles)
    }

    @Test("Должен возвращать cycles для cycles")
    @MainActor
    func returnsCyclesForCycles() {
        let viewModel = WorkoutPreviewViewModel()
        let result = viewModel.displayExecutionType(for: .cycles)
        #expect(result == .cycles)
    }

    @Test("Должен возвращать sets для sets")
    @MainActor
    func returnsSetsForSets() {
        let viewModel = WorkoutPreviewViewModel()
        let result = viewModel.displayExecutionType(for: .sets)
        #expect(result == .sets)
    }
}
