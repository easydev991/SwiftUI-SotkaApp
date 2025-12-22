import SwiftUI

struct DayActivitySelectionView: View {
    @Environment(\.dismiss) private var dismiss

    private var activities: [DayActivityType] {
        DayActivityType.allCases.filter { $0 != selectedActivity }
    }

    let onSelect: (DayActivityType) -> Void
    let selectedActivity: DayActivityType?

    var body: some View {
        List(activities) { activity in
            makeButton(for: activity)
                .listRowBackground(Color.clear)
        }
    }
}

private extension DayActivitySelectionView {
    func makeButton(for activity: DayActivityType) -> some View {
        Button {
            onSelect(activity)
            if selectedActivity != nil {
                dismiss()
            }
        } label: {
            HStack {
                activity.image
                Text(activity.localizedTitle)
            }
        }
        .tint(activity.color)
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("DayActivitySelectionButton.\(activity.rawValue)")
    }
}

#Preview("Доступны все варианты") {
    DayActivitySelectionView(
        onSelect: {
            print("Выбрали активность \($0)")
        },
        selectedActivity: nil
    )
}

#Preview("Меняем тренировку") {
    DayActivitySelectionView(
        onSelect: {
            print("Выбрали активность \($0)")
        },
        selectedActivity: .workout
    )
}
