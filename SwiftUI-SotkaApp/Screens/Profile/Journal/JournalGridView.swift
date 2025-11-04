import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct JournalGridView: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.currentDay) private var currentDay
    @Environment(\.modelContext) private var modelContext
    @State private var dayForConfirmationDialog: Int?
    @State private var activityForCommentSheet: DayActivity?
    private let itemHeight: CGFloat = 44
    let activitiesByDay: [Int: DayActivity]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(journalSections) { section in
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
        .sheet(item: $activityForCommentSheet) { activity in
            EditCommentSheet(activity: activity)
        }
    }
}

private extension JournalGridView {
    var journalSections: [InfopostSection] {
        InfopostSection.journalSections
    }

    func makeSectionView(for section: InfopostSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.localizedTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            makeGridView(for: section)
        }
    }

    func makeGridView(for section: InfopostSection) -> some View {
        LazyVGrid(
            columns: .init(repeating: GridItem(.flexible(), spacing: 8), count: 7),
            spacing: 8
        ) {
            ForEach(section.days, id: \.self) { day in
                makeDayButton(for: day)
                    .disabled(day > currentDay)
            }
            if section == .conclusion {
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
#Preview("День 50") {
    JournalGridView(activitiesByDay: User.previewWithActivities.activitiesByDay)
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
        .modelContainer(PreviewModelContainer.make(with: .previewWithActivities))
        .environment(\.currentDay, 50)
}
#endif
