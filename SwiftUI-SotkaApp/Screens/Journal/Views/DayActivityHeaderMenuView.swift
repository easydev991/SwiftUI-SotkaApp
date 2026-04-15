import SWDesignSystem
import SwiftUI

struct DayActivityHeaderMenuView<MenuContent: View>: View {
    @Environment(\.currentDay) private var currentDay
    let day: Int
    let activity: DayActivity?
    @ViewBuilder let menuContent: () -> MenuContent

    var body: some View {
        HStack(spacing: 8) {
            DayActivityHeaderView(
                dayNumber: day,
                activityDate: activity?.createDate
            )
            if day <= currentDay {
                Menu(content: menuContent) {
                    Image(systemName: activity == nil ? "plus" : "ellipsis")
                        .symbolVariant(.circle)
                }
            }
        }
        .animation(.default, value: activity)
    }
}

#if DEBUG
#Preview("С активностью") {
    DayActivityHeaderMenuView(
        day: 1,
        activity: .createNonWorkoutActivity(
            day: 1,
            activityType: .stretch,
            user: .preview
        )
    ) {
        Text("Menu Content")
    }
    .environment(\.currentDay, 15)
}

#Preview("Без активности") {
    DayActivityHeaderMenuView(day: 10, activity: nil) {
        Text("Menu Content")
    }
    .environment(\.currentDay, 15)
}
#endif
