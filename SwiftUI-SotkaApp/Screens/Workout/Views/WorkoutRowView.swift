import SWDesignSystem
import SwiftUI

struct WorkoutRowView: View {
    let title: String
    let state: WorkoutState
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            leadingView
            trailingView
        }
        .animation(.default, value: state)
    }
}

private extension WorkoutRowView {
    var leadingView: some View {
        HStack(spacing: 12) {
            Text(title)
                .fontWeight(state.isActive ? .bold : .regular)
            if state.isActive {
                Text(.workoutInProgress)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var trailingView: some View {
        switch state {
        case .active:
            Button(.workoutCompleteStep, action: action)
                .buttonStyle(SWButtonStyle(mode: .filled, size: .small, maxWidth: nil))
        case .completed:
            Image(systemName: "checkmark")
        case .inactive: EmptyView()
        }
    }
}

#Preview("Разминка/заминка") {
    VStack(spacing: 20) {
        WorkoutRowView(title: "Разминка", state: .completed, action: {})
        WorkoutRowView(title: "Разминка", state: .active, action: { print("Разминка завершена") })
        WorkoutRowView(title: "Разминка", state: .inactive, action: {})
        Divider()
        WorkoutRowView(title: "Заминка", state: .active, action: { print("Заминка завершена") })
        WorkoutRowView(title: "Заминка", state: .completed, action: {})
        WorkoutRowView(title: "Заминка", state: .inactive, action: {})
    }
}

#Preview("Подход") {
    VStack(spacing: 20) {
        WorkoutRowView(title: "Подход 1", state: .completed, action: {})
        WorkoutRowView(title: "Подход 1", state: .active, action: { print("Подход завершен") })
        WorkoutRowView(title: "Подход 1", state: .inactive, action: {})
    }
}

#Preview("Круг") {
    VStack(spacing: 20) {
        WorkoutRowView(title: "Круг 1", state: .completed, action: {})
        WorkoutRowView(title: "Круг 1", state: .active, action: { print("Круг завершен") })
        WorkoutRowView(title: "Круг 1", state: .inactive, action: {})
    }
}
