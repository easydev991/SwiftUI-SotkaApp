import Foundation
@testable import SwiftUI_SotkaApp
import SWKeychain

/// Мок для AuthHelper для тестирования WatchConnectivityManager
@MainActor
final class MockAuthHelper: AuthHelper {
    var authToken: String? = "mock-token"
    private(set) var isAuthorized = false
    private(set) var isOfflineOnly = false

    private(set) var didAuthorizeCallCount = 0
    private(set) var triggerLogoutCallCount = 0
    private(set) var performOfflineLoginCallCount = 0
    private(set) var saveAuthDataCallCount = 0
    private(set) var lastAuthData: AuthData?

    var onDidAuthorize: (() -> Void)?
    var onTriggerLogout: (() -> Void)?

    func didAuthorize() {
        isAuthorized = true
        isOfflineOnly = false
        didAuthorizeCallCount += 1
        onDidAuthorize?()
    }

    func performOfflineLogin() {
        isOfflineOnly = true
        isAuthorized = true
        authToken = nil
        performOfflineLoginCallCount += 1
    }

    func triggerLogout() {
        isAuthorized = false
        authToken = nil
        isOfflineOnly = false
        triggerLogoutCallCount += 1
        onTriggerLogout?()
    }

    func saveAuthData(_ authData: AuthData) {
        self.authData = authData
        saveAuthDataCallCount += 1
        lastAuthData = authData
        didAuthorize()
    }

    private var authData: AuthData? {
        didSet {
            if let authData {
                authToken = authData.token
            } else {
                authToken = nil
            }
        }
    }
}
