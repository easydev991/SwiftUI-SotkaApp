import Foundation

enum DayActivitySheetItem: Identifiable {
    case comment(DayActivity)
    case workoutPreview(Int)

    var id: String {
        switch self {
        case let .comment(activity):
            "comment-\(activity.day)"
        case let .workoutPreview(day):
            "workoutPreview-\(day)"
        }
    }
}
