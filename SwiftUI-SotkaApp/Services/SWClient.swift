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

enum ClientError: Error, LocalizedError {
    case forceLogout
    case noConnection

    #warning("Доделать локализацию")
    var errorDescription: String? {
        switch self {
        case .forceLogout: "ForceLogoutError"
        case .noConnection: "NoConnectionError"
        }
    }
}

enum Endpoint {
    // MARK: Авторизация
    /// **POST** ${API}/auth/login
    case login
    
    var urlPath: String {
        switch self {
        case .login: "/auth/login"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login: .post
        }
    }
    
    var hasMultipartFormData: Bool {
        switch self {
        case .login: false
        }
    }
    
    var queryItems: [URLQueryItem] {
        switch self {
        case .login: []
        }
    }
    
    var bodyParts: BodyMaker.Parts? {
        switch self {
        case .login: nil
        }
    }
}

private extension SWClient {
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
