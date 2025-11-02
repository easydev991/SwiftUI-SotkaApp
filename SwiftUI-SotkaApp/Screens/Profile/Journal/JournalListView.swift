import SwiftData
import SwiftUI

struct JournalListView: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.modelContext) private var modelContext
    let user: User

    /// Словарь активностей по номеру дня для быстрого поиска
    private var activitiesByDay: [Int: DayActivity] {
        Dictionary(user.dayActivities.map { ($0.day, $0) }, uniquingKeysWith: { $1 })
    }

    var body: some View {
        List(Array(1 ... 100), id: \.self) { day in
            makeView(for: day)
        }
        .listStyle(.plain)
    }
}

private extension JournalListView {
    @ViewBuilder
    func makeView(for day: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let activity = activitiesByDay[day]
            DayActivityHeaderView(
                dayNumber: day,
                activityDate: activity?.createDate
            )
            if let activity, let activityType = activity.activityType {
                switch activityType {
                case .workout:
                    makeTrainingView(for: activity)
                case .rest, .stretch, .sick:
                    makeLightweightView(
                        image: activityType.image,
                        title: activityType.localizedTitle
                    )
                }
            }
        }
    }

    func makeTrainingView(for activity: DayActivity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let executeType = activity.executeType,
               let count = activity.count {
                makeGenericTrainingView(
                    image: executeType.image,
                    title: executeType.localizedTitle,
                    count: count
                )
            }

            ForEach(activity.trainings.sorted(by: { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }), id: \.persistentModelID) { training in
                if let exerciseImage = exerciseImage(for: training),
                   let exerciseTitle = exerciseTitle(for: training),
                   let count = training.count {
                    makeGenericTrainingView(
                        image: exerciseImage,
                        title: exerciseTitle,
                        count: count
                    )
                }
            }
        }
    }

    func exerciseImage(for training: DayActivityTraining) -> Image? {
        if let customTypeId = training.customTypeId {
            let descriptor = FetchDescriptor<CustomExercise>(
                predicate: #Predicate { $0.id == customTypeId }
            )
            if let customExercise = try? modelContext.fetch(descriptor).first {
                return customExercise.image
            }
            return Image(systemName: "questionmark.square")
        } else if let exerciseType = training.exerciseType {
            return exerciseType.image
        }
        return nil
    }

    func exerciseTitle(for training: DayActivityTraining) -> String? {
        if let customTypeId = training.customTypeId {
            let descriptor = FetchDescriptor<CustomExercise>(
                predicate: #Predicate { $0.id == customTypeId }
            )
            if let customExercise = try? modelContext.fetch(descriptor).first {
                return customExercise.name
            }
            return nil
        } else if let exerciseType = training.exerciseType {
            return exerciseType.localizedTitle
        }
        return nil
    }

    func makeGenericTrainingView(image: Image, title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(.blue)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(count)")
        }
    }

    func makeLightweightView(image: Image, title: String) -> some View {
        HStack(spacing: 8) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(.blue)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        JournalListView(user: .previewWithActivities)
            .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
    }
    .modelContainer(PreviewModelContainer.make(with: .previewWithActivities))
}
#endif
