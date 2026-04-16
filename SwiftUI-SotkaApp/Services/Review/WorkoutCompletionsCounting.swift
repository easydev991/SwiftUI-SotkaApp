import Foundation

protocol WorkoutCompletionsCounting: Sendable {
    func completedWorkoutCount(currentUserId: Int) async -> Int
}
