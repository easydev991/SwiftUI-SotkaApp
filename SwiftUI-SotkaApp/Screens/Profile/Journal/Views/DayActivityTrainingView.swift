import SwiftData
import SwiftUI
import SWUtils

struct DayActivityTrainingView: View {
    @Environment(\.modelContext) private var modelContext
    let activity: DayActivity

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

    private func exerciseImage(for training: DayActivityTraining) -> Image {
        if let customTypeId = training.customTypeId,
           let customExercise = CustomExercise.fetch(by: customTypeId, in: modelContext) {
            customExercise.image
        } else if let exerciseType = training.exerciseType {
            exerciseType.image
        } else {
            .init(systemName: "questionmark.circle")
        }
    }

    private func exerciseTitle(for training: DayActivityTraining) -> String {
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
#Preview(traits: .sizeThatFitsLayout) {
    DayActivityTrainingView(
        activity: User.preview.activitiesByDay[7]!
    )
    .modelContainer(PreviewModelContainer.make(with: .preview))
}
#endif
