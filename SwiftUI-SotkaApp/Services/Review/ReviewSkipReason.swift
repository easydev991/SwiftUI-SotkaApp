import Foundation

enum ReviewSkipReason: Equatable {
    case alreadyAttemptedThisSession
    case recentError
    case noCurrentUser
    case milestoneNotReached
    case milestoneAlreadyAttempted
}
