import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import WatchConnectivity

/// Мок для StatusManager для тестирования
enum MockStatusManager {
    /// Создает StatusManager с моками
    /// - Parameters:
    ///   - statusClient: Мок клиента для работы со статусом (по умолчанию MockStatusClient())
    ///   - exerciseClient: Мок клиента для работы с упражнениями (по умолчанию MockExerciseClient())
    ///   - infopostsClient: Мок клиента для работы с инфопостами (по умолчанию MockInfopostsClient())
    ///   - progressClient: Мок клиента для работы с прогрессом (по умолчанию MockProgressClient())
    ///   - daysClient: Мок клиента для работы с днями (по умолчанию MockDaysClient())
    ///   - language: Язык для InfopostsService (по умолчанию "ru")
    ///   - userDefaults: UserDefaults для использования в тестах (по умолчанию создается новый изолированный MockUserDefaults)
    ///   - modelContainer: ModelContainer для использования в тестах (по умолчанию создается новый in-memory контейнер)
    ///   - watchConnectivitySessionProtocol: Протокол сессии WatchConnectivity для мокирования (по умолчанию nil)
    /// - Returns: Настроенный StatusManager с моками
    /// - Throws: `MockUserDefaults.Error.failedToCreateUserDefaults` если не удалось создать UserDefaults, или ошибки создания
    /// ModelContainer
    @MainActor
    static func create(
        statusClient: StatusClient = MockStatusClient(),
        exerciseClient: ExerciseClient = MockExerciseClient(),
        infopostsClient: InfopostsClient = MockInfopostsClient(),
        progressClient: ProgressClient = MockProgressClient(),
        daysClient: DaysClient = MockDaysClient(),
        language: String = "ru",
        userDefaults: UserDefaults? = nil,
        modelContainer: ModelContainer? = nil,
        watchConnectivitySessionProtocol: WCSessionProtocol? = nil
    ) throws -> StatusManager {
        let defaults = try userDefaults ?? MockUserDefaults.create()
        let container: ModelContainer
        if let providedContainer = modelContainer {
            container = providedContainer
        } else {
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(
                for: User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
        }
        return StatusManager(
            customExercisesService: CustomExercisesService(client: exerciseClient),
            infopostsService: InfopostsService(
                language: language,
                infopostsClient: infopostsClient
            ),
            progressSyncService: ProgressSyncService(client: progressClient),
            dailyActivitiesService: DailyActivitiesService(client: daysClient),
            statusClient: statusClient,
            modelContainer: container,
            userDefaults: defaults,
            watchConnectivitySessionProtocol: watchConnectivitySessionProtocol
        )
    }
}

extension StatusManager {
    #if DEBUG
    /// Тестовый метод для симуляции активации WCSession
    func simulateWCSessionActivation() async {
        sendApplicationContextOnActivation()
    }
    #endif
}
