import Foundation

/// Состояние этапа тренировки
struct WorkoutStepState: Identifiable {
    let step: WorkoutStep
    var state: WorkoutState

    var id: String { step.id }
}
