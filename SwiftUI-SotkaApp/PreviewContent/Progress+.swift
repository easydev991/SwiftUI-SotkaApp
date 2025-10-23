#if DEBUG
import Foundation

extension UserProgress {
    /// Превью для первого дня (начальные результаты)
    static var previewDay1: UserProgress {
        UserProgress(
            id: 1,
            pullUps: nil,
            pushUps: 15,
            squats: 25,
            weight: 75.5
        )
    }

    /// Превью для 49-го дня (средние результаты)
    static var previewDay49: UserProgress {
        UserProgress(
            id: 49,
            pullUps: 12,
            pushUps: 35,
            squats: 50,
            weight: 72.0
        )
    }

    /// Превью для 100-го дня (финальные результаты)
    static var previewDay100: UserProgress {
        UserProgress(
            id: 100,
            pullUps: 20,
            pushUps: 60,
            squats: 80,
            weight: 70.0
        )
    }
}
#endif
