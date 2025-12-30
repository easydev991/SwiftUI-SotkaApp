import SwiftUI

/// Упрощенная версия `DayActivityTrainingView` для Apple Watch
struct WatchDayActivityTrainingView: View {
    let workoutData: WorkoutData
    let executionCount: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let executeType = workoutData.exerciseExecutionType,
               let executionCount {
                ActivityRowView(
                    image: executeType.image,
                    title: executeType.localizedTitle,
                    count: executionCount
                )
            }
            ForEach(workoutData.trainings.sorted, id: \.id) { training in
                if let count = training.count {
                    ActivityRowView(
                        image: training.exerciseImage,
                        title: training.makeExerciseTitle(
                            dayNumber: workoutData.day,
                            selectedExecutionType: workoutData.exerciseExecutionType
                        ),
                        count: count
                    )
                }
            }
        }
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
