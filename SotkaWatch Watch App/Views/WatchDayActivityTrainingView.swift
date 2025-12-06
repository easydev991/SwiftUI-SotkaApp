import SwiftUI

/// Упрощенная версия `DayActivityTrainingView` для Apple Watch
struct WatchDayActivityTrainingView: View {
    let workoutData: WorkoutData
    let executionCount: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let executeType = workoutData.exerciseExecutionType,
               let executionCount {
                WatchActivityRowView(
                    image: executeType.image,
                    title: executeType.localizedTitle,
                    count: executionCount
                )
            }
            ForEach(workoutData.trainings.sorted, id: \.id) { training in
                if let count = training.count {
                    WatchActivityRowView(
                        image: exerciseImage(for: training),
                        title: exerciseTitle(for: training),
                        count: count
                    )
                }
            }
        }
    }

    private func exerciseImage(for training: WorkoutPreviewTraining) -> Image {
        if let typeId = training.typeId,
           let exerciseType = ExerciseType(rawValue: typeId) {
            exerciseType.image
        } else {
            .init(systemName: "questionmark.circle")
        }
    }

    private func exerciseTitle(for training: WorkoutPreviewTraining) -> String {
        if let typeId = training.typeId,
           let exerciseType = ExerciseType(rawValue: typeId),
           let executeType = workoutData.exerciseExecutionType {
            return exerciseType.makeLocalizedTitle(
                workoutData.day,
                executionType: executeType,
                sortOrder: training.sortOrder
            )
        } else if let typeId = training.typeId,
                  let exerciseType = ExerciseType(rawValue: typeId) {
            return exerciseType.localizedTitle
        }
        return String(localized: .exerciseTypeUnknown)
    }
}

/// Упрощенная версия `ActivityRowView` для Apple Watch
struct WatchActivityRowView: View {
    @ScaledMetric(relativeTo: .caption) private var imageSize: CGFloat = 16
    let image: Image
    let title: String
    let count: Int?

    init(image: Image, title: String, count: Int? = nil) {
        self.image = image
        self.title = title
        self.count = count
    }

    var body: some View {
        HStack(spacing: 6) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .foregroundStyle(.blue)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let count {
                Text("\(count)")
                    .bold()
            }
        }
        .font(.caption)
    }
}

#Preview {
    WatchDayActivityTrainingView(
        workoutData: .init(
            day: 10,
            executionType: ExerciseExecutionType.cycles.rawValue,
            trainings: [
                .init(
                    count: 10,
                    typeId: ExerciseType.pullups.rawValue,
                    sortOrder: 0
                ),
                .init(
                    count: 20,
                    typeId: ExerciseType.pushups.rawValue,
                    sortOrder: 1
                ),
                .init(
                    count: 30,
                    typeId: ExerciseType.squats.rawValue,
                    sortOrder: 2
                )
            ],
            plannedCount: 4
        ),
        executionCount: 4
    )
}
