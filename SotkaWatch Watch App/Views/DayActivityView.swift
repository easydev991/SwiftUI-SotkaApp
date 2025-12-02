import SwiftUI

struct DayActivityView: View {
    private let activities = DayActivityType.allCases
    let onSelect: (DayActivityType) -> Void
    let dayNumber: Int
    let selectedActivity: DayActivityType?

    var body: some View {
        NavigationStack {
            ZStack {
                if let selectedActivity {
                    SelectedActivityView(
                        activity: selectedActivity,
                        onSelect: onSelect
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
        dayNumber: 10,
        selectedActivity: nil
    )
}

#Preview("День 10 с выбранной активностью") {
    @Previewable @State var activity: DayActivityType? = .workout
    DayActivityView(
        onSelect: {
            print("Выбрали активность \($0)")
            activity = $0
        },
        dayNumber: 10,
        selectedActivity: activity
    )
}
