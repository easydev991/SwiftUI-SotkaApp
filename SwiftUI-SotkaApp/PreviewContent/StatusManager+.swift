#if DEBUG
import Foundation
import SwiftData

extension StatusManager {
    static var preview: StatusManager {
        let schema = Schema(
            [
                User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self,
                SyncJournalEntry.self,
                CalendarExtensionRecord.self
            ]
        )
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try! ModelContainer(for: schema, configurations: config)

        return StatusManager(
            customExercisesService: .init(
                client: MockExerciseClient(result: .success)
            ),
            infopostsService: .init(
                language: "ru",
                infopostsClient: MockInfopostsClient(result: .success),
                analytics: AnalyticsService(providers: [NoopAnalyticsProvider()])
            ),
            progressSyncService: ProgressSyncService(client: MockProgressClient(result: .success)),
            dailyActivitiesService: DailyActivitiesService(client: MockDaysClient(result: .success)),
            statusClient: MockLoginClient(result: .success),
            modelContainer: modelContainer
        )
    }

    static var previewWithCalendarExtension: StatusManager {
        let statusManager = preview
        let context = statusManager.modelContainer.mainContext
        let user = User.preview
        context.insert(user)
        try? context.save()

        statusManager.setCurrentDayForDebug(100)
        statusManager.addExtensionDate(.now, isSynced: true)
        return statusManager
    }

    static var previewWithCalendarExtensionDay130: StatusManager {
        let statusManager = preview
        let context = statusManager.modelContainer.mainContext
        let user = User.preview
        context.insert(user)
        try? context.save()

        statusManager.setCurrentDayForDebug(130, extensionCount: 1)
        return statusManager
    }
}
#endif
