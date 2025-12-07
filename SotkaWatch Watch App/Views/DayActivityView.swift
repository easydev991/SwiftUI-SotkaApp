import SwiftUI

struct DayActivityView: View {
    private let activities = DayActivityType.allCases
    let onSelect: (DayActivityType) -> Void
    let onDelete: (Int) -> Void
    let dayNumber: Int
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
                        dayNumber: dayNumber,
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
            .navigationTitle(.day(number: dayNumber))
        }
    }
}

#Preview("День 10, активность не выбрана") {
    DayActivityView(
        onSelect: {
            print("Выбрали активность \($0)")
        },
        onDelete: { _ in },
        dayNumber: 10,
        selectedActivity: nil,
        workoutData: nil,
        workoutExecutionCount: nil,
        comment: nil
    )
}

#Preview("День 10 с выбранной активностью") {
    @Previewable @State var activity: DayActivityType? = .workout
    DayActivityView(
        onSelect: {
            print("Выбрали активность \($0)")
            activity = $0
        },
        onDelete: { _ in },
        dayNumber: 10,
        selectedActivity: activity,
        workoutData: nil,
        workoutExecutionCount: nil,
        comment: nil
    )
}
