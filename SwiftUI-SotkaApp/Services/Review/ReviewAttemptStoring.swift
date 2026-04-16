import Foundation

protocol ReviewAttemptStoring: Sendable {
    func attemptedMilestones() -> [ReviewMilestone]
    func markAttempted(_ milestone: ReviewMilestone)
    func lastReviewRequestAttemptDate() -> Date?
}
