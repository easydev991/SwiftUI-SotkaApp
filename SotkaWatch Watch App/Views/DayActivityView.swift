import SwiftUI

struct DayActivityView: View {
    @Environment(\.currentDay) private var currentDay
    private let activities = DayActivityType.allCases
    let onSelect: (DayActivityType) -> Void
    let onDelete: (Int) -> Void
    let selectedActivity: DayActivityType?
    let workoutData: WorkoutData?
    let workoutExecutionCount: Int?
    let comment: String?

    var body: some View {
        NavigationStack {
            ZStack {
                if let selectedActivity {
                    SelectedActivityView(
                        activity: selectedActivity,
                        onSelect: onSelect,
                        onDelete: onDelete,
                        workoutData: workoutData,
                        workoutExecutionCount: workoutExecutionCount,
                        comment: comment
                    )
                } else {
                    DayActivitySelectionView(
                        onSelect: onSelect,
                        selectedActivity: nil
                    )
                }
            }
            .animation(.default, value: selectedActivity)
            .navigationTitle(.day(number: currentDay))
        }
    }
}

#Preview("День 10, активность не выбрана") {
    DayActivityView(
        onSelect: {
            print("Выбрали активность \($0)")
        },
        onDelete: { _ in },
        selectedActivity: nil,
        workoutData: nil,
        workoutExecutionCount: nil,
        comment: nil
    )
    .currentDay(10)
}

#Preview("День 10 с выбранной активностью") {
    @Previewable @State var activity: DayActivityType? = .workout
    DayActivityView(
        onSelect: {
            print("Выбрали активность \($0)")
            activity = $0
        },
        onDelete: { _ in },
        selectedActivity: activity,
        workoutData: nil,
        workoutExecutionCount: nil,
        comment: nil
    )
    .currentDay(10)
}
