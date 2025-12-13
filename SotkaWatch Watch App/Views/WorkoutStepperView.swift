import SwiftUI

struct WorkoutStepperView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var value: Int
    let from: Int
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            Stepper(
                value: $value,
                in: from ... Int.max
            ) {
                Text(value.description)
            }
            Button(.done) {
                dismiss()
            }
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
