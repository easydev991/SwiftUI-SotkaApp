import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для displayExecutionType")
    @MainActor
    struct DisplayExecutionTypeTests {
        @Test("Должен возвращать sets для turbo дней с подходами", arguments: [93, 95, 98])
        func displayExecutionTypeForTurboDaysWithSets(day: Int) {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = day
            let result = viewModel.displayExecutionType(for: .turbo)
            #expect(result == .sets)
        }

        @Test("Должен возвращать cycles для turbo дней с кругами", arguments: [92, 94, 96, 97])
        func displayExecutionTypeForTurboDaysWithCycles(day: Int) {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = day
            let result = viewModel.displayExecutionType(for: .turbo)
            #expect(result == .cycles)
        }

        @Test("Должен возвращать cycles для cycles")
        func returnsCyclesForCycles() {
            let viewModel = WorkoutPreviewViewModel()
            let result = viewModel.displayExecutionType(for: .cycles)
            #expect(result == .cycles)
        }

        @Test("Должен возвращать sets для sets")
        func returnsSetsForSets() {
            let viewModel = WorkoutPreviewViewModel()
            let result = viewModel.displayExecutionType(for: .sets)
            #expect(result == .sets)
        }
    }
}
