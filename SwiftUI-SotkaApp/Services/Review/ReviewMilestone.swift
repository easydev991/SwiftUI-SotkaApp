import Foundation

enum ReviewMilestone: Int, CaseIterable {
    case first = 1
    case tenth = 10
    case thirtieth = 30

    static func milestone(forCompletedWorkoutCount count: Int) -> ReviewMilestone? {
        ReviewMilestone.allCases
            .filter { $0.rawValue <= count }
            .max(by: { $0.rawValue < $1.rawValue })
    }

    static func isMilestoneWorkoutCount(_ count: Int) -> Bool {
        ReviewMilestone(rawValue: count) != nil
    }
}
