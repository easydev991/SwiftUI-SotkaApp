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

extension SWClient: LoginClient {
    func logIn(with token: String?) async throws -> Int {
        struct Response: Decodable { let userId: Int }
        let endpoint = Endpoint.login
        let finalComponents = try await makeComponents(for: endpoint, with: token)
        let result: Response = try await service.requestData(components: finalComponents)
        return result.userId
    }
    
    func getUserByID(_ userID: Int) async throws -> UserResponse {
        let endpoint = Endpoint.getUser(id: userID)
        return try await makeResult(for: endpoint)
    }
    
    func resetPassword(for login: String) async throws {
        let endpoint = Endpoint.resetPassword(login: login)
        try await makeStatus(for: endpoint)
    }
}

extension SWClient: ProfileClient {
    func editUser(_ id: Int, model: MainUserForm) async throws -> UserResponse {
        let endpoint = Endpoint.editUser(id: id, form: model)
        return try await makeResult(for: endpoint)
    }
    
    func changePassword(current: String, new: String) async throws {
        let endpoint = Endpoint.changePassword(currentPass: current, newPass: new)
        try await makeStatus(for: endpoint)
    }
}

extension SWClient: CountryClient {
    func getCountries() async throws -> [CountryResponse] {
        let endpoint = Endpoint.getCountries
        return try await makeResult(for: endpoint)
    }
}

extension SWClient: StatusClient {
    func start(date: String) async throws -> CurrentRun {
        let endpoint = Endpoint.start(date)
        return try await makeResult(for: endpoint)
    }
    
    func current() async throws -> CurrentRun {
        let endpoint = Endpoint.current
        return try await makeResult(for: endpoint)
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
    // MARK: Получить список стран/городов
    /// **GET** ${API}/countries
    case getCountries
    
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
    
    // MARK: Изменить данные пользователя
    /// **POST** ${API}/users/<user_id>
    case editUser(id: Int, form: MainUserForm)
    
    // MARK: Изменить пароль
    /// **POST** ${API}/auth/changepass
    case changePassword(currentPass: String, newPass: String)
    
    // MARK: Стартовать сотку
    /// **POST** ${API}/100/start
    case start(_ date: String)
    
    // MARK: Статус сотки пользователя
    /// **GET** ${API}/100/current_run
    case current
    
    var urlPath: String {
        switch self {
        case .getCountries: "/countries"
        case .login: "/auth/login"
        case let .getUser(id): "/users/\(id)"
        case .resetPassword: "/auth/reset"
        case let .editUser(userID, _): "/users/\(userID)"
        case .changePassword: "/auth/changepass"
        case .start: "/100/start"
        case .current: "/100/current_run"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .resetPassword, .editUser, .changePassword, .start: .post
        case .getUser, .getCountries, .current: .get
        }
    }
    
    var hasMultipartFormData: Bool {
        switch self {
        case .editUser: true
        case .login, .getUser, .resetPassword, .getCountries, .changePassword, .start, .current: false
        }
    }
    
    var queryItems: [URLQueryItem] {
        switch self {
        case .login, .getUser, .resetPassword, .getCountries, .editUser, .changePassword, .start, .current: []
        }
    }
    
    var bodyParts: BodyMaker.Parts? {
        switch self {
        case .login, .getUser, .getCountries, .current:
            return nil
        case let .editUser(_, form):
            let parameters: [String: String] = [
                "name": form.userName,
                "fullname": form.fullName,
                "email": form.email,
                "gender": form.genderCode.description,
                "country_id": form.country.id,
                "city_id": form.city.id,
                "birth_date": form.birthDateIsoString
            ]
            let mediaFiles: [BodyMaker.MediaFile]? = if let image = form.image {
                [
                    BodyMaker.MediaFile(
                        key: "image",
                        filename: "\(UUID().uuidString).jpg",
                        data: image.data,
                        mimeType: image.mimeType
                    )
                ]
            } else {
                nil
            }
            return .init(parameters, mediaFiles)
        case let .changePassword(current, new):
            return .init(["password": current, "new_password": new], nil)
        case let .resetPassword(login):
            return .init(["username_or_email": login], nil)
        case let .start(date):
            return .init(["date": date], nil)
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
