//
//  Client+.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 23.05.2025.
//

import Foundation

struct MockLoginClient: LoginClient {
    let result: MockResult
    
    func logIn(with token: String?) async throws -> Int {
        print("Имитируем запрос logIn")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно авторизовались")
            return UserResponse.preview.id
        case let .failure(error):
            throw error
        }
    }
    
    func getUserByID(_ userID: Int) async throws -> UserResponse {
        print("Имитируем запрос getUserByID")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно получили данные пользователя")
            return .preview
        case let .failure(error):
            throw error
        }
    }
    
    func resetPassword(for login: String) async throws {
        print("Имитируем запрос resetPassword")
        try await Task.sleep(for: .seconds(1))
        switch result {
        case .success:
            print("Успешно сбросили пароль")
        case let .failure(error):
            throw error
        }
    }
}
