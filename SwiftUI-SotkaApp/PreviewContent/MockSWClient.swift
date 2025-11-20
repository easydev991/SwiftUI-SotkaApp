#if DEBUG
/// Единый мок-клиент для UI-тестов, реализующий все протоколы
struct MockSWClient: Sendable {
    private let loginClient: MockLoginClient
    private let exerciseClient: MockExerciseClient
    private let progressClient: MockProgressClient
    private let infopostsClient: MockInfopostsClient
    private let daysClient: MockDaysClient
    private let profileClient: MockProfileClient
    private let countriesClient: MockCountriesClient

    init(instantResponse: Bool = true) {
        self.loginClient = MockLoginClient(result: .success, instantResponse: instantResponse)
        self.exerciseClient = MockExerciseClient(result: .success, instantResponse: instantResponse)
        self.progressClient = MockProgressClient(result: .success, instantResponse: instantResponse)
        self.infopostsClient = MockInfopostsClient(result: .success, instantResponse: instantResponse)
        self.daysClient = MockDaysClient(result: .success, instantResponse: instantResponse)
        self.profileClient = MockProfileClient(result: .success, instantResponse: instantResponse)
        self.countriesClient = MockCountriesClient(result: .success, instantResponse: instantResponse)
    }
}

extension MockSWClient: LoginClient {
    func logIn(with token: String?) async throws -> Int {
        try await loginClient.logIn(with: token)
    }

    func getUserByID(_ userID: Int) async throws -> UserResponse {
        try await loginClient.getUserByID(userID)
    }

    func resetPassword(for login: String) async throws {
        try await loginClient.resetPassword(for: login)
    }
}

extension MockSWClient: StatusClient {
    func start(date: String) async throws -> CurrentRunResponse {
        try await loginClient.start(date: date)
    }

    func current() async throws -> CurrentRunResponse {
        try await loginClient.current()
    }
}

extension MockSWClient: ExerciseClient {
    func getCustomExercises() async throws -> [CustomExerciseResponse] {
        try await exerciseClient.getCustomExercises()
    }

    func saveCustomExercise(id: String, exercise: CustomExerciseRequest) async throws -> CustomExerciseResponse {
        try await exerciseClient.saveCustomExercise(id: id, exercise: exercise)
    }

    func deleteCustomExercise(id: String) async throws {
        try await exerciseClient.deleteCustomExercise(id: id)
    }
}

extension MockSWClient: InfopostsClient {
    func getReadPosts() async throws -> [Int] {
        try await infopostsClient.getReadPosts()
    }

    func setPostRead(day: Int) async throws {
        try await infopostsClient.setPostRead(day: day)
    }

    func deleteAllReadPosts() async throws {
        try await infopostsClient.deleteAllReadPosts()
    }
}

extension MockSWClient: ProgressClient {
    func getProgress() async throws -> [ProgressResponse] {
        try await progressClient.getProgress()
    }

    func getProgress(day: Int) async throws -> ProgressResponse {
        try await progressClient.getProgress(day: day)
    }

    func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
        try await progressClient.createProgress(progress: progress)
    }

    func updateProgress(day: Int, progress: ProgressRequest) async throws -> ProgressResponse {
        try await progressClient.updateProgress(day: day, progress: progress)
    }

    func deleteProgress(day: Int) async throws {
        try await progressClient.deleteProgress(day: day)
    }

    func deletePhoto(day: Int, type: String) async throws {
        try await progressClient.deletePhoto(day: day, type: type)
    }
}

extension MockSWClient: DaysClient {
    func getDays() async throws -> [DayResponse] {
        try await daysClient.getDays()
    }

    func createDay(_ day: DayRequest) async throws -> DayResponse {
        try await daysClient.createDay(day)
    }

    func updateDay(model: DayRequest) async throws -> DayResponse {
        try await daysClient.updateDay(model: model)
    }

    func deleteDay(day: Int) async throws {
        try await daysClient.deleteDay(day: day)
    }
}

extension MockSWClient: ProfileClient {
    func editUser(_ id: Int, model: MainUserForm) async throws -> UserResponse {
        try await profileClient.editUser(id, model: model)
    }

    func changePassword(current: String, new: String) async throws {
        try await profileClient.changePassword(current: current, new: new)
    }
}

extension MockSWClient: CountriesClient {
    func getCountries() async throws -> [CountryResponse] {
        try await countriesClient.getCountries()
    }
}
#endif
