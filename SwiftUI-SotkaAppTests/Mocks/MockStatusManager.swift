import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import WatchConnectivity

/// Мок для StatusManager для тестирования
enum MockStatusManager {
    /// Создает StatusManager с моками
    /// - Parameters:
    ///   - language: Язык для InfopostsService (по умолчанию "ru")
    ///   - userDefaults: UserDefaults для использования в тестах (по умолчанию создается новый изолированный MockUserDefaults)
    ///   - modelContainer: ModelContainer для использования в тестах (по умолчанию создается новый in-memory контейнер)
    ///   - watchConnectivitySessionProtocol: Протокол сессии WatchConnectivity для мокирования (по умолчанию nil)
    /// - Returns: Настроенный StatusManager с моками
    /// - Throws: `MockUserDefaults.Error.failedToCreateUserDefaults` если не удалось создать UserDefaults, или ошибки создания
    /// ModelContainer
    @MainActor
    static func create(
        language: String = "ru",
        userDefaults: UserDefaults? = nil,
        modelContainer: ModelContainer? = nil,
        watchConnectivitySessionProtocol: WCSessionProtocol? = nil,
        reviewEventReporter: (any ReviewEventReporting)? = nil
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
                CalendarExtensionRecord.self,
                configurations: modelConfiguration
            )
        }
        return StatusManager(
            customExercisesService: CustomExercisesService(),
            infopostsService: InfopostsService(
                language: language,
                analytics: AnalyticsService(providers: [NoopAnalyticsProvider()])
            ),
            dailyActivitiesService: DailyActivitiesService(),
            modelContainer: container,
            userDefaults: defaults,
            watchConnectivitySessionProtocol: watchConnectivitySessionProtocol,
            reviewEventReporter: reviewEventReporter,
            isReadOnlyMode: false
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
