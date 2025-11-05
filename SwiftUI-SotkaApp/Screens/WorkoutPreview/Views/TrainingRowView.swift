import SwiftUI
import SWUtils

struct TrainingRowView: View {
    let id: String
    let image: Image
    let title: String
    let count: Int?
    let onAction: (String, TrainingRowAction) -> Void
    let isDisabled: Bool

    init(
        id: String,
        image: Image,
        title: String,
        count: Int?,
        onAction: @escaping (String, TrainingRowAction) -> Void,
        isDisabled: Bool = false
    ) {
        self.id = id
        self.image = image
        self.title = title
        self.count = count
        self.onAction = onAction
        self.isDisabled = isDisabled
    }

    var body: some View {
        HStack(spacing: 8) {
            ActivityRowView(
                image: image,
                title: title,
                count: count
            )
            Stepper(.trainingRowViewStepperLabel, value: countBinding, in: 0 ... Int.max)
                .labelsHidden()
                .disabled(isDisabled)
        }
    }

    private var countBinding: Binding<Int> {
        .init(
            get: { count ?? 0 },
            set: { newValue in
                let oldValue = count ?? 0
                if newValue > oldValue {
                    onAction(id, .increment)
                } else if newValue < oldValue {
                    onAction(id, .decrement)
                }
            }
        )
    }
}

#if DEBUG
#Preview {
    TrainingRowView(
        id: "test-id",
        image: ExerciseType.pullups.image,
        title: ExerciseType.pullups.localizedTitle,
        count: 10,
        onAction: { _, _ in }
    )
}
#endif
