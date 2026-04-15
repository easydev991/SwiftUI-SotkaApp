import SwiftData
import SwiftUI
import SWUtils

struct DayActivityTrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trainings: [DayActivityTraining]
    let activity: DayActivity

    init(activity: DayActivity) {
        self.activity = activity

        let activityDay = activity.day
        _trainings = Query(
            FetchDescriptor<DayActivityTraining>(
                predicate: #Predicate { training in
                    training.dayActivity?.day == activityDay
                },
                sortBy: [SortDescriptor(\.sortOrder)]
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let executeType = activity.executeType,
               let count = activity.count {
                ActivityRowView(
                    image: executeType.image,
                    title: executeType.localizedTitle,
                    count: count
                )
            }
            ForEach(Array(trainingSnapshots.enumerated()), id: \.offset) { _, training in
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

    private var trainingSnapshots: [WorkoutPreviewTraining] {
        trainings.workoutPreviewTrainingsSorted
    }

    private func exerciseImage(for training: WorkoutPreviewTraining) -> Image {
        if let customTypeId = training.customTypeId,
           let customExercise = CustomExercise.fetch(by: customTypeId, in: modelContext) {
            customExercise.image
        } else if let typeId = training.typeId,
                  let exerciseType = ExerciseType(rawValue: typeId) {
            exerciseType.image
        } else {
            .init(systemName: "questionmark.circle")
        }
    }

    private func exerciseTitle(for training: WorkoutPreviewTraining) -> String {
        if let customTypeId = training.customTypeId,
           let customExercise = CustomExercise.fetch(by: customTypeId, in: modelContext) {
            return customExercise.name
        } else if let typeId = training.typeId,
                  let exerciseType = ExerciseType(rawValue: typeId) {
            return exerciseType.localizedTitle
        }
        return String(localized: .exerciseTypeUnknown)
    }
}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    DayActivityTrainingView(
        activity: User.preview.activitiesByDay[7]!
    )
    .modelContainer(PreviewModelContainer.make(with: .preview))
}
#endif
