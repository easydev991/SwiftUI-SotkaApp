import SwiftUI

enum WorkoutExerciseEditorRowMode {
    case removable
    case addable

    var systemImageName: String {
        switch self {
        case .removable: "minus"
        case .addable: "plus"
        }
    }
}

struct WorkoutExerciseEditorRowView: View {
    let image: Image
    let title: String
    let mode: WorkoutExerciseEditorRowMode
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            actionButton
            ActivityRowView(
                image: image,
                title: title,
                count: nil
            )
            if mode == .removable {
                dragHandle
            }
        }
    }

    private var actionButton: some View {
        Button(
            role: mode == .removable ? .destructive : nil,
            action: onAction
        ) {
            Image(systemName: mode.systemImageName)
                .symbolVariant(.circle.fill)
                .foregroundStyle(mode == .removable ? .red : .accentColor)
                .font(.title3)
        }
        .buttonStyle(.plain)
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .foregroundStyle(.secondary)
            .font(.body)
    }
}

#if DEBUG
#Preview("Removable mode") {
    WorkoutExerciseEditorRowView(
        image: ExerciseType.pullups.image,
        title: ExerciseType.pullups.localizedTitle,
        mode: .removable,
        onAction: {}
    )
}

#Preview("Addable mode") {
    WorkoutExerciseEditorRowView(
        image: ExerciseType.pushups.image,
        title: ExerciseType.pushups.localizedTitle,
        mode: .addable,
        onAction: {}
    )
}
#endif
