import Foundation
@testable import SotkaWatch_Watch_App
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для методов работы с комментарием")
    @MainActor
    struct CommentTests {
        @Test("canEditComment должен возвращать true когда isWorkoutCompleted == true")
        func canEditCommentReturnsTrueWhenWorkoutCompleted() {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.handleWorkoutResult(WorkoutResult(count: 5, duration: 100))

            #expect(viewModel.canEditComment)
        }

        @Test("canEditComment должен возвращать true когда wasOriginallyPassed == true")
        func canEditCommentReturnsTrueWhenOriginallyPassed() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            let workoutData = WorkoutData(
                day: 50,
                executionType: ExerciseExecutionType.cycles.rawValue,
                trainings: [
                    WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
                ],
                plannedCount: 4
            )
            connectivityService.mockWorkoutData = workoutData
            connectivityService.mockWorkoutExecutionCount = 4
            await viewModel.loadData(day: 50)

            #expect(viewModel.canEditComment)
        }

        @Test("canEditComment должен возвращать false когда оба флага false")
        func canEditCommentReturnsFalseWhenBothFlagsFalse() async throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            let workoutData = WorkoutData(
                day: 50,
                executionType: ExerciseExecutionType.cycles.rawValue,
                trainings: [
                    WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
                ],
                plannedCount: 4
            )
            connectivityService.mockWorkoutData = workoutData
            connectivityService.mockWorkoutExecutionCount = nil
            await viewModel.loadData(day: 50)

            #expect(!viewModel.canEditComment)
        }

        @Test("updateComment должен обновлять комментарий на новое значение")
        func updateCommentUpdatesCommentToNewValue() throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.updateComment("Новый комментарий")

            let comment = try #require(viewModel.comment)
            #expect(comment == "Новый комментарий")
        }

        @Test("updateComment должен удалять комментарий при передаче nil")
        func updateCommentRemovesCommentWhenNil() {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.comment = "Старый комментарий"
            viewModel.updateComment(nil)

            #expect(viewModel.comment == nil)
        }

        @Test("updateComment должен заменять существующий комментарий")
        func updateCommentReplacesExistingComment() throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.comment = "Первый комментарий"
            viewModel.updateComment("Второй комментарий")

            let comment = try #require(viewModel.comment)
            #expect(comment == "Второй комментарий")
        }
    }
}
