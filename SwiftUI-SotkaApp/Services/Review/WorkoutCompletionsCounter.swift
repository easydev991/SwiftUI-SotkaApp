import Foundation
import SwiftData

@MainActor
struct WorkoutCompletionsCounter: WorkoutCompletionsCounting {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func completedWorkoutCount(currentUserId: Int) async -> Int {
        let context = modelContainer.mainContext
        let workoutTypeRaw = DayActivityType.workout.rawValue

        let predicate = #Predicate<DayActivity> { activity in
            activity.activityTypeRaw == workoutTypeRaw &&
                activity.count != nil &&
                !activity.shouldDelete
        }

        let descriptor = FetchDescriptor<DayActivity>(predicate: predicate)

        do {
            let activities = try context.fetch(descriptor)
            return activities.count(where: { $0.user?.id == currentUserId })
        } catch {
            return 0
        }
    }
}
