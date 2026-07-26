import Foundation

struct ReviewStorage: ReviewAttemptStoring, @unchecked Sendable {
    private static let namespace = "review."
    static let attemptedMilestones = namespace + "attemptedMilestones"
    static let lastReviewRequestAttemptDate = namespace + "lastReviewRequestAttemptDate"

    private let defaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }

    func attemptedMilestones() -> [ReviewMilestone] {
        let rawValues = defaults.object(forKey: Self.attemptedMilestones) as? [Int] ?? []
        return rawValues.compactMap { ReviewMilestone(rawValue: $0) }
    }

    func markAttempted(_ milestone: ReviewMilestone) {
        var existing = attemptedMilestones()
        if !existing.contains(milestone) {
            existing.append(milestone)
            defaults.set(existing.map(\.rawValue), forKey: Self.attemptedMilestones)
        }
        defaults.set(Date(), forKey: Self.lastReviewRequestAttemptDate)
    }

    func lastReviewRequestAttemptDate() -> Date? {
        defaults.object(forKey: Self.lastReviewRequestAttemptDate) as? Date
    }

    func reset() {
        defaults.removeObject(forKey: Self.attemptedMilestones)
        defaults.removeObject(forKey: Self.lastReviewRequestAttemptDate)
    }
}
