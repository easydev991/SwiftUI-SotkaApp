import Foundation

enum WorkoutStep: Equatable {
    case warmUp
    case exercise(ExerciseExecutionType, number: Int)
    case coolDown

    var localizedTitle: String {
        switch self {
        case .warmUp: String(localized: .workoutStepWarmUp)
        case let .exercise(execution, number):
            execution.localizedShortTitle + " \(number)"
        case .coolDown: String(localized: .workoutStepCoolDown)
        }
    }
}

extension WorkoutStep: Identifiable {
    var id: String {
        switch self {
        case .warmUp: "warmUp"
        case let .exercise(executionType, number):
            "\(executionType.rawValue)-\(number)"
        case .coolDown: "coolDown"
        }
    }
}
