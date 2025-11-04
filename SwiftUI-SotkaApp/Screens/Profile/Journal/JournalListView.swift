import SwiftData
import SwiftUI
import SWUtils

struct JournalListView: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.currentDay) private var currentDay
    @Environment(\.modelContext) private var modelContext
    @State private var dayForConfirmationDialog: Int?
    @State private var activityForCommentSheet: DayActivity?
    let activitiesByDay: [Int: DayActivity]
    let sortOrder: SortOrder

    var body: some View {
        List(InfopostSection.sectionsSortedBy(sortOrder), rowContent: makeSectionView)
            .animation(.default, value: sortOrder)
            .confirmationDialog(
                .journalDeleteEntry,
                isPresented: $dayForConfirmationDialog.mappedToBool(),
                titleVisibility: .visible
            ) {
                confirmationDialogContent
            } message: {
                if let day = dayForConfirmationDialog {
                    Text(.journalDeleteEntryMessage(day))
                }
            }
            .sheet(item: $activityForCommentSheet) { activity in
                EditCommentSheet(activity: activity)
            }
    }
}

private extension JournalListView {
    func makeSectionView(for section: InfopostSection) -> some View {
        Section(section.localizedTitle) {
            ForEach(section.daysSortedBy(sortOrder), id: \.self) { day in
                makeRowView(for: day)
                    .listRowInsets(
                        .init(
                            top: 24,
                            leading: 16,
                            bottom: 24,
                            trailing: 16
                        )
                    )
                    .disabled(day > currentDay)
            }
        }
    }

    func makeRowView(for day: Int) -> some View {
        let activity = activitiesByDay[day]
        return VStack(alignment: .leading, spacing: 16) {
            DayActivityHeaderMenuView(day: day, activity: activity) {
                DayActivityMenuView(
                    day: day,
                    activity: activity,
                    onComment: { day in
                        if let activity = activitiesByDay[day] {
                            activityForCommentSheet = activity
                        }
                    },
                    onDelete: { day in
                        dayForConfirmationDialog = day
                    },
                    onSelectType: { day, activityType in
                        if activityType == .workout {
                            print("TODO: настроить тренировку, день \(day)")
                        }
                        activitiesService.set(activityType, for: day, context: modelContext)
                    }
                )
            }
            if let activity {
                DayActivityContentView(activity: activity)
                    .transition(.scale.combined(with: .opacity))
                DayActivityCommentView(comment: activity.comment)
            }
        }
        .animation(.default, value: activity)
    }

    @ViewBuilder
    var confirmationDialogContent: some View {
        if let dayForConfirmationDialog,
           let activity = activitiesByDay[dayForConfirmationDialog] {
            Button(.journalDelete, role: .destructive) {
                activitiesService.deleteDailyActivity(activity, context: modelContext)
                self.dayForConfirmationDialog = nil
            }
        }
    }
}

#if DEBUG
#Preview("День 7, по возрастанию") {
    NavigationStack {
        JournalListView(
            activitiesByDay: User.previewWithActivities.activitiesByDay,
            sortOrder: .forward
        )
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
    }
    .modelContainer(PreviewModelContainer.make(with: .previewWithActivities))
    .environment(\.currentDay, 7)
}

#Preview("День 100, по убыванию") {
    NavigationStack {
        JournalListView(
            activitiesByDay: User.previewWithActivities.activitiesByDay,
            sortOrder: .reverse
        )
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
    }
    .modelContainer(PreviewModelContainer.make(with: .previewWithActivities))
    .environment(\.currentDay, 100)
}
#endif
