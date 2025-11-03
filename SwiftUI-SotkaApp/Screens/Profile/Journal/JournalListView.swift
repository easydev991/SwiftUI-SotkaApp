import SwiftData
import SwiftUI
import SWUtils

struct JournalListView: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.currentDay) private var currentDay
    @Environment(\.modelContext) private var modelContext
    @State private var dayForConfirmationDialog: Int?
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
        VStack(alignment: .leading, spacing: 16) {
            let activity = activitiesByDay[day]
            makeHeaderView(for: day, activity: activity)
            if let activity, let activityType = activity.activityType {
                switch activityType {
                case .workout:
                    makeTrainingView(for: activity)
                case .rest, .stretch, .sick:
                    ActivityRowView(
                        image: activityType.image,
                        title: activityType.localizedTitle
                    )
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

    func makeHeaderView(for day: Int, activity: DayActivity?) -> some View {
        HStack(spacing: 8) {
            DayActivityHeaderView(
                dayNumber: day,
                activityDate: activity?.createDate
            )
            if day <= currentDay {
                Menu {
                    makeMenuContent(for: day, activity: activity)
                } label: {
                    Image(systemName: activity == nil ? "plus" : "ellipsis")
                        .symbolVariant(.circle)
                }
            }
        }
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

    func makeTrainingView(for activity: DayActivity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let executeType = activity.executeType,
               let count = activity.count {
                ActivityRowView(
                    image: executeType.image,
                    title: executeType.localizedTitle,
                    count: count
                )
            }
            ForEach(activity.trainings.sorted, id: \.persistentModelID) { training in
                if let count = training.count {
                    ActivityRowView(
                        image: exerciseImage(for: training),
                        title: exerciseTitle(for: training),
                        count: count
                    )
                }
            }
        }
    }

    func exerciseImage(for training: DayActivityTraining) -> Image {
        if let customTypeId = training.customTypeId,
           let customExercise = CustomExercise.fetch(by: customTypeId, in: modelContext) {
            customExercise.image
        } else if let exerciseType = training.exerciseType {
            exerciseType.image
        } else {
            .init(systemName: "questionmark.circle")
        }
    }

    func exerciseTitle(for training: DayActivityTraining) -> String {
        if let customTypeId = training.customTypeId,
           let customExercise = CustomExercise.fetch(by: customTypeId, in: modelContext) {
            return customExercise.name
        } else if let exerciseType = training.exerciseType {
            return exerciseType.localizedTitle
        }
        return String(localized: .exerciseTypeUnknown)
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
