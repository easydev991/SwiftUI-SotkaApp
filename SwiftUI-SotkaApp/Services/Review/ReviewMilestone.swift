import Foundation

enum ReviewMilestone: Int, CaseIterable {
    case first = 1
    case tenth = 10
    case thirtieth = 30

    static func milestone(forCompletedWorkoutCount count: Int) -> ReviewMilestone? {
        ReviewMilestone(rawValue: count)
    }

    static func isMilestoneWorkoutCount(_ count: Int) -> Bool {
        milestone(forCompletedWorkoutCount: count) != nil
    }
}
