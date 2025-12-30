import SwiftUI

struct WorkoutStepperView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var localValue: Int
    @Binding private var value: Int
    private let from: Int
    private let title: String

    init(value: Binding<Int>, from: Int, title: String) {
        self._value = value
        self._localValue = .init(wrappedValue: value.wrappedValue)
        self.from = from
        self.title = title
    }

    var body: some View {
        VStack(spacing: 16) {
            Stepper(
                value: $localValue,
                in: from ... Int.max
            ) {
                Text(localValue.description)
            }
            .accessibilityIdentifier("WorkoutStepperView.stepper")
            Button(.done) {
                value = localValue
                dismiss()
            }
            .accessibilityIdentifier("WorkoutStepperView.doneButton")
        }
        .navigationTitle(title)
    }
}

#Preview {
    @Previewable @State var value = 1
    NavigationStack {
        WorkoutStepperView(
            value: $value,
            from: 1,
            title: String(localized: .pushUps)
        )
    }
}
