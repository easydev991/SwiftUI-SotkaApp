import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct WatchAuthServiceTests {
    @Test("Читает статус авторизации из UserDefaults")
    func readsAuthStatusFromUserDefaults() throws {
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(true, forKey: Constants.isAuthorizedKey)
        let service = WatchAuthService(userDefaults: userDefaults)

        let isAuthorized = service.checkAuthStatus()
        #expect(isAuthorized)
        #expect(service.isAuthorized)
    }

    @Test("Возвращает false если статус авторизации не установлен")
    func returnsFalseWhenAuthStatusNotSet() throws {
        let userDefaults = try MockUserDefaults.create()
        let service = WatchAuthService(userDefaults: userDefaults)

        let isAuthorized = service.checkAuthStatus()
        #expect(!isAuthorized)
        #expect(!service.isAuthorized)
    }

    @Test("Возвращает false если App Group UserDefaults недоступен")
    func returnsFalseWhenAppGroupUnavailable() {
        let service = WatchAuthService(userDefaults: nil)

        let isAuthorized = service.checkAuthStatus()
        #expect(!isAuthorized)
        #expect(!service.isAuthorized)
    }

    @Test("Использует правильный ключ для чтения статуса")
    func usesCorrectKeyForReadingStatus() throws {
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(true, forKey: Constants.isAuthorizedKey)
        let service = WatchAuthService(userDefaults: userDefaults)

        // checkAuthStatus() уже вызывается в init, проверяем результат
        let valueFromUserDefaults = userDefaults.bool(forKey: Constants.isAuthorizedKey)
        #expect(valueFromUserDefaults)
        #expect(service.isAuthorized)

        // Дополнительно проверяем, что метод возвращает правильное значение
        let statusFromMethod = service.checkAuthStatus()
        #expect(statusFromMethod)
    }

    @Test("Обновляет статус авторизации при получении команды от iPhone")
    func updatesAuthStatusWhenReceivingCommandFromPhone() throws {
        let userDefaults = try MockUserDefaults.create()
        let service = WatchAuthService(userDefaults: userDefaults)

        #expect(!service.isAuthorized)

        service.updateAuthStatus(true)
        #expect(service.isAuthorized)

        service.updateAuthStatus(false)
        #expect(!service.isAuthorized)
    }
}
