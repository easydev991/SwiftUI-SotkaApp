import Foundation
import Observation
@testable import SotkaWatch_Watch_App

/// Мок для WatchAuthService для тестирования
@MainActor
@Observable
final class MockWatchAuthService: WatchAuthServiceProtocol {
    var isAuthorized: Bool

    init(isAuthorized: Bool = false) {
        self.isAuthorized = isAuthorized
    }

    func checkAuthStatus() -> Bool {
        isAuthorized
    }

    func updateAuthStatus(_ isAuthorized: Bool) {
        self.isAuthorized = isAuthorized
    }
}
