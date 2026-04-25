import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct JournalGridView: View {
    @Environment(\.analyticsService) private var analytics
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(StatusManager.self) private var statusManager
    @Environment(\.currentDay) private var currentDay
    @Environment(\.modelContext) private var modelContext
    @State private var dayForConfirmationDialog: Int?
    @State private var sheetItem: DayActivitySheetItem?
    private let itemHeight: CGFloat = 44
    let activitiesByDay: [Int: DayActivity]
    let selectedPage: Int
    let pageDaysRange: ClosedRange<Int>
    let pageSections: [JournalSection]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                legendView
                ForEach(pageSections) { section in
                    makeSectionView(for: section)
                }
            }
            .padding()
        }
        .confirmationDialog(
            .journalDeleteEntry,
            isPresented: .constant(dayForConfirmationDialog != nil),
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

private extension JournalGridView {
    var legendView: some View {
        ViewThatFits {
            // Вариант для ландшафтной ориентации - все элементы по горизонтали
            HStack(spacing: 24) {
                ForEach(DayActivityType.allCases, content: makeLegendItemView)
            }
            // Вариант для портретной ориентации - сетка 2x2
            LazyVGrid(
                columns: .init(repeating: GridItem(.flexible(), spacing: 8), count: 2),
                spacing: 8
            ) {
                ForEach(DayActivityType.allCases) { activityType in
                    makeLegendItemView(for: activityType)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    func makeLegendItemView(for activityType: DayActivityType) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(activityType.color)
                .frame(width: 16, height: 16)
            Text(activityType.localizedTitle)
        }
    }

    func makeSectionView(for section: JournalSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            makeGridView(for: section)
        }
    }

    func makeGridView(for section: JournalSection) -> some View {
        LazyVGrid(
            columns: .init(repeating: GridItem(.flexible(), spacing: 8), count: 7),
            spacing: 8
        ) {
            ForEach(section.days, id: \.self) { day in
                makeDayButton(for: day)
                    .disabled(!JournalGridPagination.isDayEnabled(day: day, currentDay: currentDay))
            }
            if selectedPage == 0, pageDaysRange.upperBound == DayCalculator.baseProgramDays,
               section.days.last == DayCalculator.baseProgramDays {
                ForEach(0 ..< 5, id: \.self) { _ in
                    Color.clear.frame(height: itemHeight)
                }
            }
        }
    }

    func makeDayButton(for day: Int) -> some View {
        let activity = activitiesByDay[day]
        let textColor = activity != nil ? Color.contrastText : .swMainText
        let activityColor = activity?.activityType?.color ?? Color.gray.opacity(0.2)
        let isToday = day == currentDay
        return Menu {
            DayActivityMenuView(
                day: day,
                activity: activity,
                onComment: { day in
                    analytics.log(.userAction(action: .editJournalEntry(dayNumber: "\(day)")))
                    if let activity = activitiesByDay[day] {
                        sheetItem = .comment(activity)
                    }
                },
                onDelete: { day in
                    analytics.log(.userAction(action: .deleteJournalEntry(dayNumber: "\(day)")))
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
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(activityColor)
                .frame(height: itemHeight)
                .overlay {
                    Text("\(day)")
                        .bold()
                        .foregroundStyle(textColor)
                        .opacity(day > currentDay ? 0.6 : 1)
                }
                .overlay {
                    if isToday {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.swMainText, lineWidth: 2)
                    }
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(.day(number: day))
        .accessibilityValue(activity?.activityType?.localizedTitle ?? String(localized: .dayNotCompleted))
        .accessibilityIdentifier("JournalGridMenuButton.\(day)")
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
#Preview("День 50") {
    JournalGridView(
        activitiesByDay: User.preview.activitiesByDay,
        selectedPage: 0,
        pageDaysRange: 1 ... 100,
        pageSections: JournalGridPagination.makeSections(totalDays: 100, page: 0)
    )
    .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
    .environment(StatusManager.preview)
    .modelContainer(PreviewModelContainer.make(with: .preview))
    .environment(\.currentDay, 50)
}

#Preview("День 130, страница 101-200") {
    JournalGridView(
        activitiesByDay: User.preview.activitiesByDay,
        selectedPage: 1,
        pageDaysRange: 101 ... 200,
        pageSections: JournalGridPagination.makeSections(totalDays: 300, page: 1)
    )
    .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
    .environment(StatusManager.previewWithCalendarExtensionDay130)
    .modelContainer(PreviewModelContainer.make(with: .preview))
    .environment(\.currentDay, 130)
}
#endif
