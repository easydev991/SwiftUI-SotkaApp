import SwiftData
import SwiftUI
import SWUtils

struct JournalListView: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(StatusManager.self) private var statusManager
    @Environment(\.currentDay) private var currentDay
    @Environment(\.modelContext) private var modelContext
    @State private var dayForConfirmationDialog: Int?
    @State private var sheetItem: DayActivitySheetItem?
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
            .sheet(item: $sheetItem) { item in
                switch item {
                case let .comment(activity):
                    EditCommentSheet(activity: activity)
                case let .workoutPreview(day):
                    WorkoutPreviewScreen(activitiesService: activitiesService, day: day)
                }
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
                            sheetItem = .comment(activity)
                        }
                    },
                    onDelete: { day in
                        dayForConfirmationDialog = day
                    },
                    onSelectType: { day, activityType in
                        if activityType == .workout {
                            sheetItem = .workoutPreview(day)
                        }
                        activitiesService.set(activityType, for: day, context: modelContext)
                    }
                )
            }
            if let activity {
                VStack(spacing: 8) {
                    makeDayActivityContentView(for: activity)
                    DayActivityCommentView(comment: activity.comment)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.default, value: activity)
    }

    @ViewBuilder
    func makeDayActivityContentView(for activity: DayActivity) -> some View {
        let contentView = DayActivityContentView(activity: activity)
        if activity.activityType == .workout {
            Button {
                sheetItem = .workoutPreview(activity.day)
            } label: {
                contentView.contentShape(.rect)
            }
            .buttonStyle(.plain)
        } else {
            contentView
        }
    }

    @ViewBuilder
    var confirmationDialogContent: some View {
        if let dayForConfirmationDialog,
           let activity = activitiesByDay[dayForConfirmationDialog] {
            Button(.journalDelete, role: .destructive) {
                activitiesService.deleteDailyActivity(activity, context: modelContext)

                // Отправляем статус на часы, если это текущий день
                if activity.day == currentDay {
                    statusManager.sendCurrentStatus(isAuthorized: true, currentDay: currentDay, currentActivity: nil)
                }

                self.dayForConfirmationDialog = nil
            }
        }
    }
}

#if DEBUG
#Preview("День 7, по возрастанию") {
    NavigationStack {
        JournalListView(
            activitiesByDay: User.preview.activitiesByDay,
            sortOrder: .forward
        )
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
    }
    .modelContainer(PreviewModelContainer.make(with: .preview))
    .environment(\.currentDay, 7)
}

#Preview("День 100, по убыванию") {
    NavigationStack {
        JournalListView(
            activitiesByDay: User.preview.activitiesByDay,
            sortOrder: .reverse
        )
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
    }
    .modelContainer(PreviewModelContainer.make(with: .preview))
    .environment(\.currentDay, 100)
}
#endif
