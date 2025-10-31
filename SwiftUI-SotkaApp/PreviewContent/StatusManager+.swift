#if DEBUG
import Foundation

extension StatusManager {
    static var preview: StatusManager {
        StatusManager(
            customExercisesService: .init(
                client: MockExerciseClient(result: .success)
            ),
            infopostsService: .init(
                language: "ru",
                infopostsClient: MockInfopostsClient(result: .success)
            ),
            progressSyncService: ProgressSyncService(client: MockProgressClient(result: .success)),
            dailyActivitiesService: DailyActivitiesService(client: MockDaysClient(result: .success))
        )
    }
}
#endif
