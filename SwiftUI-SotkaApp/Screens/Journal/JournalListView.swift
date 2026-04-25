import SwiftData
import SwiftUI
import SWUtils

struct JournalListView: View {
    @Environment(\.analyticsService) private var analytics
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(StatusManager.self) private var statusManager
    @Environment(\.currentDay) private var currentDay
    @Environment(\.modelContext) private var modelContext
    @State private var dayForConfirmationDialog: Int?
    @State private var sheetItem: DayActivitySheetItem?
    let activitiesByDay: [Int: DayActivity]
    let totalDays: Int
    let sortOrder: SortOrder
    let selectedPage: Int

    var body: some View {
        Group {
            if shouldRenderFlatPage {
                List(flatDays, id: \.self, rowContent: makeRowViewForList)
            } else {
                List(sectionDays, rowContent: makeSectionView)
            }
        }
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
    var shouldRenderFlatPage: Bool {
        paginationContent.shouldRenderFlatPage
    }

    var sectionDays: [JournalSection] {
        paginationContent.sections
    }

    var flatDays: [Int] {
        paginationContent.flatDays
    }

    var paginationContent: JournalListPagination.Content {
        JournalListPagination.makeContent(
            totalDays: totalDays,
            sortOrder: sortOrder,
            selectedPage: selectedPage
        )
    }

    func makeSectionView(for section: JournalSection) -> some View {
        Section(section.title) {
            ForEach(section.days, id: \.self) { day in
                makeRowView(for: day)
                    .listRowInsets(
                        .init(
                            top: 24,
                            leading: 16,
                            bottom: 24,
                            trailing: 16
                        )
                    )
                    .disabled(!JournalGridPagination.isDayEnabled(day: day, currentDay: currentDay))
            }
        }
    }

    func makeRowViewForList(for day: Int) -> some View {
        makeRowView(for: day)
            .listRowInsets(
                .init(
                    top: 24,
                    leading: 16,
                    bottom: 24,
                    trailing: 16
                )
            )
            .disabled(!JournalGridPagination.isDayEnabled(day: day, currentDay: currentDay))
    }

    func makeRowView(for day: Int) -> some View {
        let activity = activitiesByDay[day]
        return VStack(alignment: .leading, spacing: 16) {
            DayActivityHeaderMenuView(day: day, activity: activity) {
                DayActivityMenuView(
                    day: day,
                    activity: activity,
                    onComment: { day in
                        analytics.log(.userAction(
                            action: .editJournalEntry(dayNumber: "\(day)")
                        )
                        )
                        if let activity = activitiesByDay[day] {
                            sheetItem = .comment(activity)
                        }
                    },
                    onDelete: { day in
                        analytics.log(.userAction(
                            action: .deleteJournalEntry(dayNumber: "\(day)")
                        )
                        )
                        dayForConfirmationDialog = day
                    },
                    onSelectType: { day, activityType in
                        analytics.log(
                            .userAction(
                                action: .selectActivityType(
                                    type: String(activityType.rawValue),
                                    dayNumber: "\(day)"
                                )
                            )
                        )
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
                    statusManager.sendCurrentStatus(
                        isAuthorized: true,
                        currentDay: currentDay,
                        currentActivity: nil
                    )
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
            totalDays: 100,
            sortOrder: .forward,
            selectedPage: 0
        )
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
        .environment(StatusManager.preview)
    }
    .modelContainer(PreviewModelContainer.make(with: .preview))
    .environment(\.currentDay, 7)
}

#Preview("День 100, по убыванию") {
    NavigationStack {
        JournalListView(
            activitiesByDay: User.preview.activitiesByDay,
            totalDays: 100,
            sortOrder: .reverse,
            selectedPage: 0
        )
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
        .environment(StatusManager.preview)
    }
    .modelContainer(PreviewModelContainer.make(with: .preview))
    .environment(\.currentDay, 100)
}

#Preview("День 130, страница 101-200") {
    NavigationStack {
        JournalListView(
            activitiesByDay: User.preview.activitiesByDay,
            totalDays: 300,
            sortOrder: .forward,
            selectedPage: 1
        )
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
        .environment(StatusManager.previewWithCalendarExtensionDay130)
    }
    .modelContainer(PreviewModelContainer.make(with: .preview))
    .environment(\.currentDay, 130)
}

#Preview("Страница 101-200, плоский список") {
    NavigationStack {
        JournalListView(
            activitiesByDay: User.preview.activitiesByDay,
            totalDays: 300,
            sortOrder: .forward,
            selectedPage: 1
        )
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
        .environment(StatusManager.previewWithCalendarExtensionDay130)
    }
    .modelContainer(PreviewModelContainer.make(with: .preview))
    .environment(\.currentDay, 130)
}
#endif
