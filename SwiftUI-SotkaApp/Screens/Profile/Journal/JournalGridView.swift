import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct JournalGridView: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.currentDay) private var currentDay
    @Environment(\.modelContext) private var modelContext
    @State private var dayForConfirmationDialog: Int?
    private let itemHeight: CGFloat = 44
    let user: User

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
    }
}

private extension JournalGridView {
    struct JournalSection: Identifiable {
        let id: InfopostSection
        let section: InfopostSection
        let days: [Int]
    }

    var journalSections: [JournalSection] {
        [
            JournalSection(
                id: .base,
                section: .base,
                days: Array(1 ... 49)
            ),
            JournalSection(
                id: .advanced,
                section: .advanced,
                days: Array(50 ... 91)
            ),
            JournalSection(
                id: .turbo,
                section: .turbo,
                days: Array(92 ... 98)
            ),
            JournalSection(
                id: .conclusion,
                section: .conclusion,
                days: Array(99 ... 100)
            )
        ]
    }

    func makeSectionView(for journalSection: JournalSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(journalSection.section.localizedTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            makeGridView(for: journalSection)
        }
    }

    func makeGridView(for journalSection: JournalSection) -> some View {
        let spacing: CGFloat = 8
        return LazyVGrid(
            columns: .init(repeating: GridItem(.flexible(), spacing: spacing), count: 7),
            spacing: spacing
        ) {
            ForEach(journalSection.days, id: \.self) { day in
                makeDayButton(for: day)
                    .disabled(day > currentDay)
            }
            if journalSection.section == .conclusion {
                ForEach(0 ..< 5, id: \.self) { _ in
                    Color.clear.frame(height: itemHeight)
                }
            }
        }
    }

    func makeDayButton(for day: Int) -> some View {
        let activity = user.activitiesByDay[day]
        let textColor = activity != nil ? Color.contrastText : .swMainText
        let activityColor = activity?.activityType?.color ?? Color.gray.opacity(0.2)
        let isToday = day == currentDay
        return Menu {
            makeMenuContent(for: day, activity: activity)
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
    }

    @ViewBuilder
    func makeMenuContent(for day: Int, activity: DayActivity?) -> some View {
        Label("День \(day)", systemImage: "calendar")
        Divider()
        if let activity {
            if let currentActivityType = activity.activityType {
                if currentActivityType == .workout {
                    Button(.journalEdit) {
                        print("TODO: изменить тренировку, день \(day)")
                    }
                } else {
                    Menu(.journalEdit) {
                        ForEach(DayActivityType.allCases.filter { $0 != currentActivityType }) { type in
                            Button(type.localizedTitle) {
                                print("TODO: изменить день \(day) на \(type.localizedTitle)")
                            }
                        }
                    }
                }
            }
            Button(.journalComment) {
                print("TODO: комментировать день \(day)")
            }
            Button(.journalDelete, role: .destructive) {
                dayForConfirmationDialog = day
            }
        } else {
            ForEach(DayActivityType.allCases) { activityType in
                Button(activityType.localizedTitle) {
                    print("TODO: выбрать \(activityType.localizedTitle) для дня \(day)")
                }
            }
        }
    }

    @ViewBuilder
    var confirmationDialogContent: some View {
        if let day = dayForConfirmationDialog {
            Button(.journalDelete, role: .destructive) {
                print("TODO: удалить день \(day)")
                dayForConfirmationDialog = nil
            }
        }
    }
}

#if DEBUG
#Preview {
    JournalGridView(user: .previewWithActivities)
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
        .environment(\.currentDay, 50)
}
#endif
