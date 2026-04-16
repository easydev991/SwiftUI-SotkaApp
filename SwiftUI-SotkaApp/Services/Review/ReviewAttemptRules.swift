import Foundation

enum ReviewAttemptRules {
    static func shouldAttemptMilestone(
        milestone: ReviewMilestone,
        attemptedMilestones: [ReviewMilestone]
    ) -> Bool {
        !attemptedMilestones.contains(milestone)
    }
}
