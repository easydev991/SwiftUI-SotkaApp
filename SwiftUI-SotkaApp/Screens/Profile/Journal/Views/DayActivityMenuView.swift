import SwiftUI
import SWUtils

struct DayActivityMenuView: View {
    let day: Int
    let activity: DayActivity?
    let onComment: (_ day: Int) -> Void
    let onDelete: (_ day: Int) -> Void
    let onSelectType: (_ day: Int, _ type: DayActivityType) -> Void

    var body: some View {
        ZStack {
            Label(.day(number: day), systemImage: "calendar")
            Divider()
            if let activity {
                makeActivityMenuContent(activity)
            } else {
                ForEach(DayActivityType.allCases) { activityType in
                    Button(activityType.localizedTitle) {
                        onSelectType(day, activityType)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func makeActivityMenuContent(_ activity: DayActivity) -> some View {
        if let currentActivityType = activity.activityType {
            if currentActivityType == .workout {
                Button(.journalEdit) {
                    onSelectType(day, currentActivityType)
                }
            } else {
                Menu(.journalEdit) {
                    ForEach(DayActivityType.allCases.filter { $0 != currentActivityType }) { type in
                        Button(type.localizedTitle) {
                            onSelectType(day, type)
                        }
                    }
                }
            }
        }
        Button(.journalComment) {
            onComment(day)
        }
        Button(.journalDelete, role: .destructive) {
            onDelete(day)
        }
    }
}

#if DEBUG
#Preview("Без активности") {
    Menu {
        DayActivityMenuView(
            day: 7,
            activity: nil,
            onComment: { _ in },
            onDelete: { _ in },
            onSelectType: { _, _ in }
        )
    } label: {
        Image(systemName: "gear")
    }
}

#Preview("С активностью") {
    Menu {
        DayActivityMenuView(
            day: 7,
            activity: User.previewWithActivities.dayActivities.first,
            onComment: { _ in },
            onDelete: { _ in },
            onSelectType: { _, _ in }
        )
    } label: {
        Image(systemName: "gear")
    }
}
#endif
