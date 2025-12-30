import Foundation

/// Протокол для WatchAuthService для тестирования
@MainActor
protocol WatchAuthServiceProtocol {
    var isAuthorized: Bool { get }
    func checkAuthStatus() -> Bool
    func updateAuthStatus(_ isAuthorized: Bool)
}

/// WatchAuthService соответствует протоколу
extension WatchAuthService: WatchAuthServiceProtocol {}
