import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct WatchAuthServiceTests {
    @Test("Инициализируется с isAuthorized = false")
    func initializesWithFalseAuthStatus() {
        let service = WatchAuthService()

        #expect(!service.isAuthorized)
        #expect(!service.checkAuthStatus())
    }

    @Test("Возвращает текущий статус авторизации")
    func returnsCurrentAuthStatus() {
        let service = WatchAuthService()

        // По умолчанию false
        #expect(!service.checkAuthStatus())
        #expect(!service.isAuthorized)

        // Обновляем статус
        service.updateAuthStatus(true)
        #expect(service.checkAuthStatus())
        #expect(service.isAuthorized)
    }

    @Test("Обновляет статус авторизации при получении команды от iPhone")
    func updatesAuthStatusWhenReceivingCommandFromPhone() {
        let service = WatchAuthService()

        // Начальное состояние
        #expect(!service.isAuthorized)

        // Обновляем на true
        service.updateAuthStatus(true)
        #expect(service.isAuthorized)
        #expect(service.checkAuthStatus())

        // Обновляем на false
        service.updateAuthStatus(false)
        #expect(!service.isAuthorized)
        #expect(!service.checkAuthStatus())
    }

    @Test("Проверяет статус авторизации после обновления")
    func checksAuthStatusAfterUpdate() {
        let service = WatchAuthService()

        // Начальное состояние
        let initialStatus = service.checkAuthStatus()
        #expect(!initialStatus)

        // Обновляем статус
        service.updateAuthStatus(true)
        let updatedStatus = service.checkAuthStatus()
        #expect(updatedStatus)
    }
}
