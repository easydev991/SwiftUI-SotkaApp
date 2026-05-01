import Foundation
@testable import SwiftUI_SotkaApp

/// Мок для AuthHelper для тестирования WatchConnectivityManager
@MainActor
final class MockAuthHelper: AuthHelper {
    var authToken: String? = "mock-token"
    private(set) var isAuthorized = false
    private(set) var isOfflineOnly = false

    private(set) var triggerLogoutCallCount = 0
    private(set) var performOfflineLoginCallCount = 0

    var onTriggerLogout: (() -> Void)?

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
}
