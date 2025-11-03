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
        .accessibilityLabel(.day(number: day))
        .accessibilityValue(activity?.activityType?.localizedTitle ?? String(localized: .dayNotCompleted))
    }

    @ViewBuilder
    func makeMenuContent(for day: Int, activity: DayActivity?) -> some View {
        Label(.day(number: day), systemImage: "calendar")
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
#Preview("День 50") {
    JournalGridView(activitiesByDay: User.previewWithActivities.activitiesByDay)
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
        .environment(\.currentDay, 50)
}
#endif
