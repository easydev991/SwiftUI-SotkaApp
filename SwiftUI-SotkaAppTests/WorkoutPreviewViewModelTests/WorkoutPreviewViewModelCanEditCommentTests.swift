import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для canEditComment")
    struct CanEditCommentTests {
        @Test("Должен возвращать true для canEditComment когда isWorkoutCompleted == true")
        @MainActor
        func returnsTrueForCanEditCommentWhenWorkoutCompleted() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.isWorkoutCompleted = true

            #expect(viewModel.canEditComment)
        }

        @Test("Должен возвращать true для canEditComment когда wasOriginallyPassed == true")
        @MainActor
        func returnsTrueForCanEditCommentWhenWasOriginallyPassed() throws {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let viewModel = WorkoutPreviewViewModel()

            let dayActivity = DayActivity(
                day: 5,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 10,
                plannedCount: 8,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                createDate: Date(),
                modifyDate: Date(),
                user: user
            )
            context.insert(dayActivity)
            try context.save()

            viewModel.updateData(modelContext: context, day: 5, restTime: 60)

            #expect(viewModel.canEditComment)
        }

        @Test("Должен возвращать false для canEditComment когда isWorkoutCompleted == false и wasOriginallyPassed == false")
        @MainActor
        func returnsFalseForCanEditCommentWhenBothFalse() {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.isWorkoutCompleted = false

            #expect(!viewModel.canEditComment)
        }
    }
}
