import Foundation
import SWUtils

/// Модель для временных показателей прогресса, пока их не сохранят в `SwiftData`
struct TempMetricsModel {
    var pullUps = ""
    var pushUps = ""
    var squats = ""
    var weight = ""

    init(
        pullUps: String = "",
        pushUps: String = "",
        squats: String = "",
        weight: String = ""
    ) {
        self.pullUps = pullUps
        self.pushUps = pushUps
        self.squats = squats
        self.weight = weight
    }

    init(progress: UserProgress) {
        self.init(
            pullUps: progress.pullUps.stringFromInt(),
            pushUps: progress.pushUps.stringFromInt(),
            squats: progress.squats.stringFromInt(),
            weight: progress.weight.stringFromFloat()
        )
    }

    var hasValidNumbers: Bool {
        let pullUpsValid = pullUps.isValidNonNegativeInteger
        let pushUpsValid = pushUps.isValidNonNegativeInteger
        let squatsValid = squats.isValidNonNegativeInteger
        let weightValid = weight.isValidNonNegativeFloat
        return pullUpsValid && pushUpsValid && squatsValid && weightValid
    }

    var hasAnyFilledValue: Bool {
        !pullUps.isEmpty || !pushUps.isEmpty || !squats.isEmpty || !weight.isEmpty
    }

    func hasChanges(to progress: UserProgress) -> Bool {
        let initialPullUps = progress.pullUps.stringFromInt()
        let initialPushUps = progress.pushUps.stringFromInt()
        let initialSquats = progress.squats.stringFromInt()
        let initialWeight = progress.weight.stringFromFloat()
        return pullUps != initialPullUps || pushUps != initialPushUps ||
            squats != initialSquats || weight != initialWeight
    }
}

extension TempMetricsModel: CustomStringConvertible {
    var description: String {
        "pullUps: \(pullUps), pushUps: \(pushUps), squats: \(squats), weight: \(weight)"
    }
}
