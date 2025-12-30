import SwiftUI

extension WorkoutPreviewTraining {
    var exerciseImage: Image {
        if let typeId,
           let exerciseType = ExerciseType(rawValue: typeId) {
            return exerciseType.image
        }
        return Image(systemName: "questionmark.circle")
    }

    func makeExerciseTitle(
        dayNumber: Int,
        selectedExecutionType: ExerciseExecutionType?
    ) -> String {
        if let typeId,
           let exerciseType = ExerciseType(rawValue: typeId),
           let selectedExecutionType {
            return exerciseType.makeLocalizedTitle(
                dayNumber,
                executionType: selectedExecutionType,
                sortOrder: sortOrder
            )
        } else if let typeId,
                  let exerciseType = ExerciseType(rawValue: typeId) {
            return exerciseType.localizedTitle
        }
        return String(localized: .exerciseTypeUnknown)
    }
}
