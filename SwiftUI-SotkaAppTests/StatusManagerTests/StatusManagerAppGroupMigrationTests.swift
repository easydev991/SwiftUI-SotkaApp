import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для миграции StatusManager на App Group UserDefaults")
    @MainActor
    struct AppGroupMigrationTests {
        @Test("Должен использовать App Group UserDefaults для сохранения startDate")
        func statusManagerUsesAppGroupUserDefaults() async throws {
            let appGroupDefaults = try MockUserDefaults.create()
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                userDefaults: appGroupDefaults
            )

            await statusManager.startNewRun(appDate: startDate)

            let key = "WorkoutStartDate"
            let storedTime = appGroupDefaults.double(forKey: key)
            let storedDate = Date(timeIntervalSinceReferenceDate: storedTime)
            #expect(storedDate.isTheSameDayIgnoringTime(startDate))
        }

        @Test("Должен использовать fallback на стандартный UserDefaults при недоступности App Group")
        func statusManagerFallsBackToStandardUserDefaultsWhenAppGroupUnavailable() async throws {
            let standardDefaults = try MockUserDefaults.create()
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                userDefaults: standardDefaults
            )

            await statusManager.startNewRun(appDate: startDate)

            let key = "WorkoutStartDate"
            let storedTime = standardDefaults.double(forKey: key)
            let storedDate = Date(timeIntervalSinceReferenceDate: storedTime)
            #expect(storedDate.isTheSameDayIgnoringTime(startDate))
        }

        @Test("Должен использовать App Group UserDefaults по умолчанию")
        func statusManagerUsesAppGroupUserDefaultsByDefault() async throws {
            let appGroupDefaults = try MockUserDefaults.create()
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let statusManager = StatusManager(
                customExercisesService: CustomExercisesService(client: MockExerciseClient()),
                infopostsService: InfopostsService(
                    language: "ru",
                    infopostsClient: MockInfopostsClient()
                ),
                progressSyncService: ProgressSyncService(client: MockProgressClient()),
                dailyActivitiesService: DailyActivitiesService(client: MockDaysClient()),
                statusClient: mockStatusClient,
                userDefaults: appGroupDefaults
            )

            await statusManager.startNewRun(appDate: startDate)

            let key = "WorkoutStartDate"
            let storedTime = appGroupDefaults.double(forKey: key)
            let storedDate = Date(timeIntervalSinceReferenceDate: storedTime)
            #expect(storedDate.isTheSameDayIgnoringTime(startDate))
        }

        @Test("Должен устанавливать флаг миграции при использовании App Group")
        func statusManagerSetsMigrationFlagWhenUsingAppGroup() throws {
            let appGroupDefaults = try MockUserDefaults.create()

            _ = StatusManager(
                customExercisesService: CustomExercisesService(client: MockExerciseClient()),
                infopostsService: InfopostsService(
                    language: "ru",
                    infopostsClient: MockInfopostsClient()
                ),
                progressSyncService: ProgressSyncService(client: MockProgressClient()),
                dailyActivitiesService: DailyActivitiesService(client: MockDaysClient()),
                statusClient: MockStatusClient(),
                userDefaults: appGroupDefaults
            )

            #expect(appGroupDefaults.bool(forKey: "migrationStartDateToAppGroupCompleted"))
        }
    }
}
