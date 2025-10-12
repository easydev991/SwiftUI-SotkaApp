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

extension SWClient: ExerciseClient {
    func getCustomExercises() async throws -> [CustomExerciseResponse] {
        let endpoint = Endpoint.getCustomExercises
        return try await makeResult(for: endpoint)
    }

    func saveCustomExercise(id: String, exercise: CustomExerciseRequest) async throws -> CustomExerciseResponse {
        let endpoint = Endpoint.saveCustomExercise(id: id, exercise: exercise)
        return try await makeResult(for: endpoint)
    }

    func deleteCustomExercise(id: String) async throws {
        let endpoint = Endpoint.deleteCustomExercise(id: id)
        try await makeStatus(for: endpoint)
    }
}

extension SWClient: InfopostsClient {
    func getReadPosts() async throws -> [Int] {
        let endpoint = Endpoint.getReadPosts
        return try await makeResult(for: endpoint)
    }

    func setPostRead(day: Int) async throws {
        let endpoint = Endpoint.setPostRead(day: day)
        try await makeStatus(for: endpoint)
    }

    func deleteAllReadPosts() async throws {
        let endpoint = Endpoint.deleteAllReadPosts
        try await makeStatus(for: endpoint)
    }
}

extension SWClient: ProgressClient {
    func getProgress() async throws -> [ProgressResponse] {
        let endpoint = Endpoint.getProgress
        return try await makeResult(for: endpoint)
    }

    func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
        let endpoint = Endpoint.createProgress(progress)
        return try await makeResult(for: endpoint)
    }

    func updateProgress(day: Int, progress: ProgressRequest) async throws -> ProgressResponse {
        let endpoint = Endpoint.updateProgress(day: day, progress: progress)
        return try await makeResult(for: endpoint)
    }

    func deleteProgress(day: Int) async throws {
        let endpoint = Endpoint.deleteProgress(day: day)
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

    // MARK: Получить список пользовательских упражнений
    /// **GET** ${API}/100/custom_exercises
    case getCustomExercises

    // MARK: Сохранить пользовательское упражнение
    /// **POST** ${API}/100/custom_exercises
    case saveCustomExercise(id: String, exercise: CustomExerciseRequest)

    // MARK: Удалить пользовательское упражнение
    /// **DELETE** ${API}/100/custom_exercises/<id>
    case deleteCustomExercise(id: String)

    // MARK: Получить прочитанные инфопосты
    /// **GET** ${API}/100/posts/read
    case getReadPosts

    // MARK: Отметить инфопост как прочитанный
    /// **POST** ${API}/100/posts/read/<day>
    case setPostRead(day: Int)

    // MARK: Удалить все прочитанные инфопосты
    /// **DELETE** ${API}/100/posts/read
    case deleteAllReadPosts

    // MARK: Получить список прогресса пользователя
    /// **GET** ${API}/100/progress
    case getProgress

    // MARK: Создать новый прогресс
    /// **POST** ${API}/100/progress
    case createProgress(_ progress: ProgressRequest)

    // MARK: Обновить существующий прогресс для конкретного дня
    /// **POST** ${API}/100/progress/<day>
    case updateProgress(day: Int, progress: ProgressRequest)

    // MARK: Удалить прогресс для конкретного дня
    /// **DELETE** ${API}/100/progress/<day>
    case deleteProgress(day: Int)

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
        case .getCustomExercises: "/100/custom_exercises"
        case let .saveCustomExercise(id, _): "/100/custom_exercises/\(id)"
        case let .deleteCustomExercise(id): "/100/custom_exercises/\(id)"
        case .getReadPosts: "/100/posts/read"
        case let .setPostRead(day): "/100/posts/read/\(day)"
        case .deleteAllReadPosts: "/100/posts/read"
        case .getProgress: "/100/progress"
        case .createProgress: "/100/progress"
        case let .updateProgress(day, _): "/100/progress/\(day)"
        case let .deleteProgress(day): "/100/progress/\(day)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .resetPassword, .editUser, .changePassword, .start, .saveCustomExercise, .setPostRead, .createProgress,
             .updateProgress: .post
        case .getUser, .getCountries, .current, .getCustomExercises, .getReadPosts, .getProgress: .get
        case .deleteCustomExercise, .deleteAllReadPosts, .deleteProgress: .delete
        }
    }

    var hasMultipartFormData: Bool {
        switch self {
        case .editUser, .createProgress, .updateProgress: true
        case .login, .getUser, .resetPassword, .getCountries, .changePassword, .start, .current, .getCustomExercises, .saveCustomExercise,
             .deleteCustomExercise, .getReadPosts, .setPostRead, .deleteAllReadPosts, .getProgress, .deleteProgress: false
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .login, .getUser, .resetPassword, .getCountries, .editUser, .changePassword, .start, .current, .getCustomExercises,
             .saveCustomExercise, .deleteCustomExercise, .getReadPosts, .setPostRead, .deleteAllReadPosts, .getProgress, .createProgress,
             .updateProgress, .deleteProgress: []
        }
    }

    var bodyParts: BodyMaker.Parts? {
        switch self {
        case .login, .getUser, .getCountries, .current, .getCustomExercises, .deleteCustomExercise, .getReadPosts, .setPostRead,
             .deleteAllReadPosts, .getProgress, .deleteProgress:
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
        case let .saveCustomExercise(_, exercise):
            let parameters: [String: String] = [
                "id": exercise.id,
                "name": exercise.name,
                "image_id": String(exercise.imageId),
                "create_date": exercise.createDate,
                "is_hidden": String(exercise.isHidden)
            ]
            if let modifyDate = exercise.modifyDate {
                var mutableParameters = parameters
                mutableParameters["modify_date"] = modifyDate
                return .init(mutableParameters, nil)
            }
            return .init(parameters, nil)
        case let .createProgress(progress), let .updateProgress(_, progress):
            let parameters: [String: String] = [
                "id": String(progress.id),
                "pullups": String(progress.pullups ?? 0),
                "pushups": String(progress.pushups ?? 0),
                "squats": String(progress.squats ?? 0),
                "weight": String(progress.weight ?? 0),
                "modify_date": progress.modifyDate
            ]

            let mediaFiles: [BodyMaker.MediaFile]? = if let photos = progress.photos, !photos.isEmpty {
                photos.compactMap { key, data -> BodyMaker.MediaFile? in
                    guard !data.isEmpty else { return nil }
                    return BodyMaker.MediaFile(
                        key: key,
                        filename: "\(UUID().uuidString).jpg",
                        data: data,
                        mimeType: "image/jpeg"
                    )
                }
            } else {
                nil
            }

            return .init(parameters, mediaFiles)
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
