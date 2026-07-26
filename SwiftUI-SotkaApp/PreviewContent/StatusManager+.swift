#if DEBUG
import Foundation
import SwiftData

extension StatusManager {
    /// Превью StatusManager для простых экранов (без продлений календаря)
    @MainActor
    static var preview: StatusManager {
        let container = PreviewModelContainer.make(with: .preview)
        return StatusManager(
            customExercisesService: CustomExercisesService(isReadOnlyMode: false),
            infopostsService: InfopostsService(
                language: "ru",
                analytics: AnalyticsService(providers: [NoopAnalyticsProvider()]),
                isReadOnlyMode: false
            ),
            dailyActivitiesService: DailyActivitiesService(isReadOnlyMode: false),
            modelContainer: container,
            isReadOnlyMode: false
        )
    }

    /// Превью StatusManager с продлением календаря
    @MainActor
    static var previewWithCalendarExtension: StatusManager {
        let manager = preview
        manager.setCurrentDayForDebug(150)
        return manager
    }

    /// Превью StatusManager с продлением календаря до 130-го дня
    @MainActor
    static var previewWithCalendarExtensionDay130: StatusManager {
        let manager = preview
        manager.setCurrentDayForDebug(130)
        return manager
    }
}
#endif
