//
//  SWClient.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 15.05.2025.
//

import Foundation
import SWNetwork

/// Сервис для обращений к серверу
struct SWClient: Sendable {
    /// Сервис, предоставляющий токен и выполняющий логаут
    let authHelper: AuthHelper
    /// Сервис для отправки запросов/получения ответов от сервера
    private let service: SWNetworkProtocol
    
    /// Инициализатор
    /// - Parameter authHelper: Сервис, предоставляющий токен и выполняющий логаут
    init(with authHelper: AuthHelper) {
        self.authHelper = authHelper
        self.service = SWNetworkService()
    }
}

extension SWClient {
    /// Выполняет авторизацию
    /// - Parameter token: Токен авторизации
    /// - Returns: `id` авторизованного пользователя
    func logIn(with token: String?) async throws -> Int {
        struct Response: Decodable { let userId: Int }
        let endpoint = Endpoint.login
        let finalComponents = try await makeComponents(for: endpoint, with: token)
        let result: Response = try await service.requestData(components: finalComponents)
        return result.userId
    }
    
    /// Запрашивает данные пользователя по `id`
    ///
    /// В случае успеха сохраняет данные главного пользователя в `defaults` и авторизует, если еще не авторизован
    /// - Parameters:
    ///   - userID: `id` пользователя
    /// - Returns: вся информация о пользователе
    func getUserByID(_ userID: Int) async throws -> UserResponse {
        let endpoint = Endpoint.getUser(id: userID)
        return try await makeResult(for: endpoint)
    }
    
    /// Сбрасывает пароль для неавторизованного пользователя с указанным логином
    /// - Parameter login: `login` пользователя
    func resetPassword(for login: String) async throws {
        let endpoint = Endpoint.resetPassword(login: login)
        try await makeStatus(for: endpoint)
    }
}

enum ClientError: Error, LocalizedError {
    case forceLogout
    case noConnection
    
    var errorDescription: String? {
        switch self {
        case .forceLogout: NSLocalizedString("Error.ForceLogout", comment: "")
        case .noConnection: NSLocalizedString("Error.NoConnection", comment: "")
        }
    }
}

enum Endpoint {
    // MARK: Авторизация
    /// **POST** ${API}/auth/login
    case login
    
    // MARK: Получить профиль пользователя
    /// **GET** ${API}/users/<user_id>
    /// `id` - идентификатор пользователя, чей профиль нужно получить
    case getUser(id: Int)
    
    // MARK: Восстановление пароля
    /// **POST** ${API}/auth/reset
    case resetPassword(login: String)
    
    var urlPath: String {
        switch self {
        case .login: "/auth/login"
        case let .getUser(id): "/users/\(id)"
        case .resetPassword: "/auth/reset"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .resetPassword: .post
        case .getUser: .get
        }
    }
    
    var hasMultipartFormData: Bool {
        switch self {
        case .login, .getUser, .resetPassword: false
        }
    }
    
    var queryItems: [URLQueryItem] {
        switch self {
        case .login, .getUser, .resetPassword: []
        }
    }
    
    var bodyParts: BodyMaker.Parts? {
        switch self {
        case .login, .getUser:
            nil
        case let .resetPassword(login):
            .init(["username_or_email": login], nil)
        }
    }
}

private extension SWClient {
    @discardableResult
    func makeStatus(for endpoint: Endpoint) async throws -> Bool {
        do {
            let finalComponents = try await makeComponents(for: endpoint)
            return try await service.requestStatus(components: finalComponents)
        } catch APIError.invalidCredentials {
            await authHelper.triggerLogout()
            throw ClientError.forceLogout
        } catch APIError.notConnectedToInternet {
            throw ClientError.noConnection
        } catch {
            throw error
        }
    }

    func makeResult<T: Decodable>(
        for endpoint: Endpoint,
        with token: String? = nil
    ) async throws -> T {
        do {
            let finalComponents = try await makeComponents(for: endpoint, with: token)
            return try await service.requestData(components: finalComponents)
        } catch APIError.invalidCredentials {
            await authHelper.triggerLogout()
            throw ClientError.forceLogout
        } catch APIError.notConnectedToInternet {
            throw ClientError.noConnection
        } catch {
            throw error
        }
    }

    func makeComponents(
        for endpoint: Endpoint,
        with token: String? = nil
    ) async throws -> RequestComponents {
        let savedToken = await authHelper.authToken
        return .init(
            path: endpoint.urlPath,
            queryItems: endpoint.queryItems,
            httpMethod: endpoint.method,
            hasMultipartFormData: endpoint.hasMultipartFormData,
            bodyParts: endpoint.bodyParts,
            token: token ?? savedToken
        )
    }
}
