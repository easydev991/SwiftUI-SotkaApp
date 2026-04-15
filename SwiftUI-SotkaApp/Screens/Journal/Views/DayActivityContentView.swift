import SwiftData
import SwiftUI

struct DayActivityContentView: View {
    @Environment(\.modelContext) private var modelContext
    let activity: DayActivity

    var body: some View {
        ZStack {
            if let activityType = activity.activityType {
                switch activityType {
                case .workout:
                    DayActivityTrainingView(activity: activity)
                case .rest, .stretch, .sick:
                    ActivityRowView(
                        image: activityType.image,
                        title: activityType.localizedTitle
                    )
                }
            }
        }
        .animation(.default, value: activity.activityType)
    }
}

#if DEBUG
#Preview("Тренировка", traits: .sizeThatFitsLayout) {
    DayActivityContentView(
        activity: User.preview.activitiesByDay[7]!
    )
    .modelContainer(PreviewModelContainer.make(with: .preview))
}
#endif
