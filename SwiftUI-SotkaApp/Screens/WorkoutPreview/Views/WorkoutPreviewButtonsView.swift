import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct WorkoutPreviewButtonsView: View {
    let isPassed: Bool
    let hasChanges: Bool
    let isWorkoutCompleted: Bool
    let showCommentField: Bool
    let onSave: () -> Void
    let onStartTraining: () -> Void

    var body: some View {
        if isWorkoutCompleted {
            workoutCompletedButtons
        } else if isPassed {
            passedDayButtons
        } else {
            notPassedDayButtons
        }
    }

    private var notPassedDayButtons: some View {
        VStack(spacing: 12) {
            Button(.workoutPreviewStartTraining, action: onStartTraining)
                .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
            Button(.workoutPreviewSaveAsPassed, action: onSave)
                .buttonStyle(SWButtonStyle(mode: .tinted, size: .large))
        }
    }

    private var passedDayButtons: some View {
        HStack(spacing: 12) {
            Button(.workoutPreviewSave, action: onSave)
                .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
                .disabled(!hasChanges)
            // TODO: Кнопка "Продолжить" - показывается только если тренировка была начата, но не завершена
        }
    }

    private var workoutCompletedButtons: some View {
        Button(.workoutPreviewSave, action: onSave)
            .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
    }
}

#if DEBUG
#Preview("Не пройденный день") {
    WorkoutPreviewButtonsView(
        isPassed: false,
        hasChanges: false,
        isWorkoutCompleted: false,
        showCommentField: false,
        onSave: {},
        onStartTraining: {}
    )
}

#Preview("Пройденный день без изменений") {
    WorkoutPreviewButtonsView(
        isPassed: true,
        hasChanges: false,
        isWorkoutCompleted: false,
        showCommentField: false,
        onSave: {},
        onStartTraining: {}
    )
}

#Preview("Пройденный день с изменениями") {
    WorkoutPreviewButtonsView(
        isPassed: true,
        hasChanges: true,
        isWorkoutCompleted: false,
        showCommentField: false,
        onSave: {},
        onStartTraining: {}
    )
}

#Preview("Тренировка завершена") {
    WorkoutPreviewButtonsView(
        isPassed: false,
        hasChanges: false,
        isWorkoutCompleted: true,
        showCommentField: true,
        onSave: {},
        onStartTraining: {}
    )
}
#endif
