import Foundation

enum ReviewStorageKeys {
    private static let namespace = "review."

    static let attemptedMilestones = namespace + "attemptedMilestones"
    static let lastReviewRequestAttemptDate = namespace + "lastReviewRequestAttemptDate"
}
