#if DEBUG
import Foundation
import SwiftData

@MainActor
extension StatusManager {
    /// Превью StatusManager для простых экранов (без продлений календаря)
    static var preview: StatusManager {
        let container = PreviewModelContainer.make(with: .preview)
        return StatusManager(
            customExercisesService: CustomExercisesService(),
            infopostsService: InfopostsService(
                language: "ru",
                analytics: AnalyticsService(providers: [NoopAnalyticsProvider()])
            ),
            dailyActivitiesService: DailyActivitiesService(),
            modelContainer: container
        )
    }

    /// Превью StatusManager с продлением календаря
    static var previewWithCalendarExtension: StatusManager {
        let manager = preview
        manager.setCurrentDayForDebug(150)
        return manager
    }

    /// Превью StatusManager с продлением календаря до 130-го дня
    static var previewWithCalendarExtensionDay130: StatusManager {
        let manager = preview
        manager.setCurrentDayForDebug(130)
        return manager
    }
}
#endif
