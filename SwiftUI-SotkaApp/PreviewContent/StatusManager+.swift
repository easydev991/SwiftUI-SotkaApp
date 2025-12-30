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
                SyncJournalEntry.self
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
                infopostsClient: MockInfopostsClient(result: .success)
            ),
            progressSyncService: ProgressSyncService(client: MockProgressClient(result: .success)),
            dailyActivitiesService: DailyActivitiesService(client: MockDaysClient(result: .success)),
            statusClient: MockLoginClient(result: .success),
            modelContainer: modelContainer
        )
    }
}
#endif
