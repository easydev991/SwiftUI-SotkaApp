import Foundation

struct ReviewStorage: ReviewAttemptStoring, @unchecked Sendable {
    private let defaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }

    func attemptedMilestones() -> [ReviewMilestone] {
        let rawValues = defaults.object(forKey: ReviewStorageKeys.attemptedMilestones) as? [Int] ?? []
        return rawValues.compactMap { ReviewMilestone(rawValue: $0) }
    }

    func markAttempted(_ milestone: ReviewMilestone) {
        var existing = attemptedMilestones()
        if !existing.contains(milestone) {
            existing.append(milestone)
            defaults.set(existing.map(\.rawValue), forKey: ReviewStorageKeys.attemptedMilestones)
        }
        defaults.set(Date(), forKey: ReviewStorageKeys.lastReviewRequestAttemptDate)
    }

    func lastReviewRequestAttemptDate() -> Date? {
        defaults.object(forKey: ReviewStorageKeys.lastReviewRequestAttemptDate) as? Date
    }

    func reset() {
        defaults.removeObject(forKey: ReviewStorageKeys.attemptedMilestones)
        defaults.removeObject(forKey: ReviewStorageKeys.lastReviewRequestAttemptDate)
    }
}
