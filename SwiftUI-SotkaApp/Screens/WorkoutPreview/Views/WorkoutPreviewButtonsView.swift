import SWDesignSystem
import SwiftUI

struct WorkoutPreviewButtonsView: View {
    let isPassed: Bool
    let hasChanges: Bool
    let isWorkoutCompleted: Bool
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
            #if os(watchOS)
                .tint(Color.swAccent)
                .buttonStyle(.borderedProminent)
            #else
                .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
            #endif
                .accessibilityIdentifier("WorkoutPreview.startTrainingButton")
            Button(.workoutPreviewSaveAsPassed, action: onSave)
            #if os(watchOS)
                .tint(Color.swAccent)
                .buttonStyle(.bordered)
            #else
                .buttonStyle(SWButtonStyle(mode: .tinted, size: .large))
                .accessibilityIdentifier("WorkoutPreview.saveAsPassedButton")
            #endif
        }
    }

    private var passedDayButtons: some View {
        HStack(spacing: 12) {
            Button(.workoutPreviewSave, action: onSave)
            #if os(watchOS)
                .tint(Color.swAccent)
                .buttonStyle(.borderedProminent)
            #else
                .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
            #endif
                .disabled(!hasChanges)
                .accessibilityIdentifier("WorkoutPreview.saveButton")
            // TODO: Кнопка "Продолжить" - показывается только если тренировка была начата, но не завершена
        }
    }

    private var workoutCompletedButtons: some View {
        Button(.workoutPreviewSave, action: onSave)
        #if os(watchOS)
            .tint(Color.swAccent)
            .buttonStyle(.borderedProminent)
        #else
            .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
        #endif
            .accessibilityIdentifier("WorkoutPreview.saveButton")
    }
}

#if DEBUG
#Preview("Не пройденный день") {
    WorkoutPreviewButtonsView(
        isPassed: false,
        hasChanges: false,
        isWorkoutCompleted: false,
        onSave: {},
        onStartTraining: {}
    )
}

#Preview("Пройденный день без изменений") {
    WorkoutPreviewButtonsView(
        isPassed: true,
        hasChanges: false,
        isWorkoutCompleted: false,
        onSave: {},
        onStartTraining: {}
    )
}

#Preview("Пройденный день с изменениями") {
    WorkoutPreviewButtonsView(
        isPassed: true,
        hasChanges: true,
        isWorkoutCompleted: false,
        onSave: {},
        onStartTraining: {}
    )
}

#Preview("Тренировка завершена") {
    WorkoutPreviewButtonsView(
        isPassed: false,
        hasChanges: false,
        isWorkoutCompleted: true,
        onSave: {},
        onStartTraining: {}
    )
}
#endif
