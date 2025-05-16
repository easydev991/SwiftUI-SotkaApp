//
//  AuthHelper.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 15.05.2025.
//

import Foundation
import SWKeychain
import Observation

@MainActor
protocol AuthHelper: AnyObject, Sendable {
    /// Токен авторизации для запросов к серверу
    var authToken: String? { get }
    /// Логаут с удалением всех данных пользователя
    func triggerLogout()
}

@MainActor
@Observable
final class AuthHelperImp: AuthHelper {
    private let defaults = UserDefaults.standard
    
    @ObservationIgnored
    @KeychainWrapper(Key.authData.rawValue)
    private var authData: AuthData?

    private(set) var isAuthorized: Bool {
        get {
            access(keyPath: \.isAuthorized)
            return defaults.bool(forKey: Key.isAuthorized.rawValue)
        }
        set {
            withMutation(keyPath: \.isAuthorized) {
                defaults.set(newValue, forKey: Key.isAuthorized.rawValue)
            }
        }
    }
    
    var authToken: String? { authData?.token }
    
    func saveAuthData(_ authData: AuthData) {
        self.authData = authData
    }
    
    func didAuthorize() {
        isAuthorized = true
    }
    
    func triggerLogout() {
        authData = nil
        isAuthorized = false
    }
}

private extension AuthHelperImp {
    enum Key: String {
        case authData
        case isAuthorized
    }
}
