import Foundation

protocol ReviewEventReporting: Sendable {
    func workoutCompletedSuccessfully(context: ReviewContext) async
}
