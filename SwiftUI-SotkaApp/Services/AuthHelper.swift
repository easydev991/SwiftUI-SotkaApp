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

    var isAuthorized: Bool { userInfo != nil }
    
    var authToken: String? { authData?.token }
    
    func saveAuthData(_ authData: AuthData) {
        self.authData = authData
    }
    
    #warning("Временный код, переделать на Swift Data")
    private(set) var userInfo: UserResponse? {
        get {
            access(keyPath: \.userInfo)
            guard let data = defaults.data(forKey: Key.userInfo.rawValue),
                  let info = try? JSONDecoder().decode(UserResponse.self, from: data)
            else {
                return nil
            }
            return info
        }
        set {
            withMutation(keyPath: \.userInfo) {
                if let newValue {
                    do {
                        let data = try JSONEncoder().encode(newValue)
                        withMutation(keyPath: \.userInfo) {
                            defaults.set(data, forKey: Key.userInfo.rawValue)
                        }
                    } catch {
                        assertionFailure("Не смогли сохранить данные пользователя")
                    }
                } else {
                    defaults.removeObject(forKey: Key.userInfo.rawValue)
                }
            }
        }
    }
    
    func didAuthorize(_ userResponse: UserResponse) {
        self.userInfo = userResponse
    }
    
    func triggerLogout() {
        authData = nil
        userInfo = nil
    }
}

private extension AuthHelperImp {
    enum Key: String {
        case authData
        case userInfo
    }
}
