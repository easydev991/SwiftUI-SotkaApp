import Foundation

protocol ReviewEventReporting: Sendable {
    func workoutCompletedSuccessfully(hadRecentError: Bool) async
}
