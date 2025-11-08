import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct WorkoutPreviewButtonsView: View {
    let isPassed: Bool
    let hasChanges: Bool
    let onSave: () -> Void
    let onStartTraining: () -> Void

    var body: some View {
        if isPassed {
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
}

#if DEBUG
#Preview("Не пройденный день") {
    WorkoutPreviewButtonsView(isPassed: false, hasChanges: false, onSave: {}, onStartTraining: {})
}

#Preview("Пройденный день без изменений") {
    WorkoutPreviewButtonsView(isPassed: true, hasChanges: false, onSave: {}, onStartTraining: {})
}

#Preview("Пройденный день с изменениями") {
    WorkoutPreviewButtonsView(isPassed: true, hasChanges: true, onSave: {}, onStartTraining: {})
}
#endif
