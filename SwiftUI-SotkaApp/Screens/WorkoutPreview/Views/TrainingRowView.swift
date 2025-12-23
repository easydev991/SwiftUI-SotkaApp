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
            Stepper(.trainingRowViewStepperLabel, value: countBinding, in: 1 ... Int.max)
                .labelsHidden()
                .disabled(isDisabled)
        }
    }

    private var countBinding: Binding<Int> {
        .init(
            get: { count ?? 1 },
            set: { newValue in
                let oldValue = count ?? 1
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
    @Previewable @State var count = 10
    TrainingRowView(
        id: "test-id",
        image: ExerciseType.pullups.image,
        title: ExerciseType.pullups.localizedTitle,
        count: count,
        onAction: { _, actionKind in
            switch actionKind {
            case .increment:
                count += 1
            case .decrement:
                count -= 1
            }
        }
    )
}
#endif
