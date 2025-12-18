import Foundation
@testable import SwiftUI_SotkaApp
import SWKeychain
import Testing

@MainActor
struct AuthHelperTests {
    @Test("Должен использовать UserDefaults для сохранения статуса авторизации")
    func authHelperUsesUserDefaults() throws {
        let userDefaults = try MockUserDefaults.create()
        let authHelper = AuthHelperImp(userDefaults: userDefaults)

        authHelper.triggerLogout()
        authHelper.didAuthorize()

        let isAuthorized = userDefaults.bool(forKey: "isAuthorized")
        #expect(isAuthorized)
        #expect(authHelper.isAuthorized)
    }

    @Test("Должен сохранять и получать статус авторизации")
    func authHelperStoresAndRetrievesAuthorizationStatus() throws {
        let userDefaults = try MockUserDefaults.create()
        let authHelper = AuthHelperImp(userDefaults: userDefaults)

        #expect(!authHelper.isAuthorized)

        authHelper.didAuthorize()
        #expect(authHelper.isAuthorized)

        authHelper.triggerLogout()
        #expect(!authHelper.isAuthorized)
    }

    @Test("Должен корректно обрабатывать выход из аккаунта")
    func authHelperHandlesLogoutCorrectly() throws {
        let userDefaults = try MockUserDefaults.create()
        let authHelper = AuthHelperImp(userDefaults: userDefaults)

        authHelper.didAuthorize()
        #expect(authHelper.isAuthorized)

        authHelper.triggerLogout()
        #expect(!authHelper.isAuthorized)
        #expect(authHelper.authToken == nil)
    }

    @Test("Должен сохранять и получать данные авторизации")
    func authHelperSavesAndRetrievesAuthData() throws {
        let userDefaults = try MockUserDefaults.create()
        let authHelper = AuthHelperImp(userDefaults: userDefaults)
        let testAuthData = AuthData(login: "test@example.com", password: "password123")

        authHelper.saveAuthData(testAuthData)

        let token = try #require(authHelper.authToken)
        #expect(!token.isEmpty)
    }

    @Test("Должен обновлять данные авторизации с новым логином")
    func authHelperUpdatesAuthDataCorrectly() throws {
        let userDefaults = try MockUserDefaults.create()
        let authHelper = AuthHelperImp(userDefaults: userDefaults)
        let initialAuthData = AuthData(login: "initial@example.com", password: "initialPassword")

        authHelper.saveAuthData(initialAuthData)
        authHelper.updateAuthData(login: "updated@example.com")

        let updatedToken = try #require(authHelper.authToken)
        #expect(!updatedToken.isEmpty)
    }

    @Test("Должен обновлять данные авторизации с новым логином и паролем")
    func authHelperUpdatesAuthDataWithNewPassword() throws {
        let userDefaults = try MockUserDefaults.create()
        let authHelper = AuthHelperImp(userDefaults: userDefaults)
        let initialAuthData = AuthData(login: "test@example.com", password: "oldPassword")

        authHelper.saveAuthData(initialAuthData)
        authHelper.updateAuthData(login: "updated@example.com", newPassword: "newPassword")

        let updatedToken = try #require(authHelper.authToken)
        #expect(!updatedToken.isEmpty)
    }

    @Test("Должен использовать правильный ключ для статуса авторизации")
    func authHelperUsesCorrectKeyForAuthorizationStatus() throws {
        let userDefaults = try MockUserDefaults.create()
        let authHelper = AuthHelperImp(userDefaults: userDefaults)

        authHelper.didAuthorize()

        let valueFromUserDefaults = userDefaults.bool(forKey: "isAuthorized")
        #expect(valueFromUserDefaults)
        #expect(authHelper.isAuthorized)
    }
}
