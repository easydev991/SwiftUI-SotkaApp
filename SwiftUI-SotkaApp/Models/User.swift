import Foundation
import OSLog
import SwiftData
import SWUtils

private let logger = Logger(subsystem: "SotkaApp", category: "User")

@Model
final class User {
    @Attribute(.unique) var id: Int
    var userName: String?
    var fullName: String?
    var email: String?
    var imageStringURL: String?
    var cityId: Int?
    var countryId: Int?
    var genderCode: Int?
    var birthDateIsoString: String?

    /// Пользовательские упражнения
    @Relationship(deleteRule: .cascade) var customExercises: [CustomExercise] = []

    /// Результаты прогресса пользователя
    @Relationship(deleteRule: .cascade) var progressResults: [UserProgress] = []

    /// Активности пользователя
    @Relationship(deleteRule: .cascade) var dayActivities: [DayActivity] = []

    /// ID избранных инфопостов (хранится как строка через запятую, например "id1,id2,id3")
    private var favoriteInfopostIdsString = ""

    /// Синхронизированные прочитанные дни инфопостов (хранится как строка через запятую, например "1,2,15")
    private var readInfopostDaysString = ""

    /// Несинхронизированные прочитанные дни инфопостов (хранится как строка через запятую, например "1,2,15")
    private var unsyncedReadInfopostDaysString = ""

    init(
        id: Int,
        userName: String? = nil,
        fullName: String? = nil,
        email: String? = nil,
        imageStringURL: String? = nil,
        cityID: Int? = nil,
        countryID: Int? = nil,
        genderCode: Int? = nil,
        birthDateIsoString: String? = nil
    ) {
        self.id = id
        self.userName = userName
        self.fullName = fullName
        self.email = email
        self.imageStringURL = imageStringURL
        self.cityId = cityID
        self.countryId = countryID
        self.genderCode = genderCode
        self.birthDateIsoString = birthDateIsoString
    }

    convenience init(from response: UserResponse) {
        self.init(
            id: response.id,
            userName: response.name,
            fullName: response.fullname,
            email: response.email,
            imageStringURL: response.image,
            cityID: response.cityId,
            countryID: response.countryId,
            genderCode: response.gender,
            birthDateIsoString: response.birthDate
        )
    }
}

extension User {
    var avatarUrl: URL? {
        imageStringURL.queryAllowedURL
    }

    var gender: Gender? {
        guard let genderCode else { return nil }
        return Gender(genderCode)
    }

    var genderWithAge: String {
        let localizedAgeString = String(localized: .ageInYears(age))
        return genderString.isEmpty
            ? localizedAgeString
            : genderString + ", " + localizedAgeString
    }

    var birthDate: Date {
        DateFormatterService.dateFromString(birthDateIsoString, format: .isoShortDate)
    }

    var customExerciseCountText: String {
        let count = customExercises.count
        return count > 0 ? "\(count)" : ""
    }

    /// Словарь активностей по номеру дня для быстрого поиска (исключает удаленные активности)
    var activitiesByDay: [Int: DayActivity] {
        Dictionary(dayActivities.filter { !$0.shouldDelete }.map { ($0.day, $0) }, uniquingKeysWith: { $1 })
    }

    /// Проверяет, заполнены ли результаты для текущего дня
    func isMaximumsFilled(for currentDay: Int) -> Bool {
        // Используем UserProgress.Section для определения дня прогресса
        let progressSection = UserProgress.Section(day: currentDay)
        let progressDay = progressSection.rawValue

        // Получаем все результаты для нужного дня
        let allResultsForDay = progressResults.filter { $0.id == progressDay }
        let activeResultsForDay = allResultsForDay.filter { !$0.shouldDelete }
        let filledActiveResults = activeResultsForDay.filter(\.isMetricsFilled)

        let logAllResults = allResultsForDay.map { "\($0.id): isMetricsFilled=\($0.isMetricsFilled), shouldDelete=\($0.shouldDelete)" }
            .joined(separator: ", ")
        let logActiveResults = activeResultsForDay.map { "\($0.id): isMetricsFilled=\($0.isMetricsFilled)" }.joined(separator: ", ")

        logger.info("isMaximumsFilled: currentDay=\(currentDay), progressDay=\(progressDay)")
        logger.info("Все результаты для дня \(progressDay): [\(logAllResults)]")
        logger.info("Активные результаты для дня \(progressDay): [\(logActiveResults)]")
        logger.info("Заполненные активные результаты: \(filledActiveResults.count)")

        // Проверяем, есть ли заполненные результаты для соответствующего дня
        // Исключаем удаленные записи (shouldDelete = true)
        let result = progressResults.contains {
            $0.id == progressDay && $0.isMetricsFilled && !$0.shouldDelete
        }

        logger.info("isMaximumsFilled результат: \(result)")
        return result
    }
}

private extension User {
    var genderString: String {
        guard let gender else { return "" }
        return gender.description
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 0
    }
}

extension User {
    /// ID избранных инфопостов
    private(set) var favoriteInfopostIds: [String] {
        get {
            guard !favoriteInfopostIdsString.isEmpty else { return [] }
            return favoriteInfopostIdsString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        }
        set {
            favoriteInfopostIdsString = newValue.isEmpty ? "" : newValue.joined(separator: ",")
        }
    }

    /// Синхронизированные прочитанные дни инфопостов
    private(set) var readInfopostDays: [Int] {
        get {
            guard !readInfopostDaysString.isEmpty else { return [] }
            return readInfopostDaysString.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
        set {
            readInfopostDaysString = newValue.isEmpty ? "" : newValue.map(String.init).joined(separator: ",")
        }
    }

    /// Несинхронизированные прочитанные дни инфопостов
    private(set) var unsyncedReadInfopostDays: [Int] {
        get {
            guard !unsyncedReadInfopostDaysString.isEmpty else { return [] }
            return unsyncedReadInfopostDaysString.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
        set {
            unsyncedReadInfopostDaysString = newValue.isEmpty ? "" : newValue.map(String.init).joined(separator: ",")
        }
    }

    // MARK: - Вспомогательные методы для работы с массивами

    /// Добавляет ID в избранные инфопосты
    func addFavoriteInfopostId(_ id: String) {
        var ids = favoriteInfopostIds
        if !ids.contains(id) {
            ids.append(id)
            favoriteInfopostIds = ids
        }
    }

    /// Удаляет ID из избранных инфопостов
    func removeFavoriteInfopostId(_ id: String) {
        var ids = favoriteInfopostIds
        ids.removeAll { $0 == id }
        favoriteInfopostIds = ids
    }

    /// Добавляет день в список прочитанных дней
    func addReadInfopostDay(_ day: Int) {
        var days = readInfopostDays
        if !days.contains(day) {
            days.append(day)
            readInfopostDays = days
        }
    }

    /// Удаляет день из списка прочитанных дней
    func removeReadInfopostDay(_ day: Int) {
        var days = readInfopostDays
        days.removeAll { $0 == day }
        readInfopostDays = days
    }

    /// Добавляет день в список несинхронизированных прочитанных дней
    func addUnsyncedReadInfopostDay(_ day: Int) {
        var days = unsyncedReadInfopostDays
        if !days.contains(day) {
            days.append(day)
            unsyncedReadInfopostDays = days
        }
    }

    /// Удаляет день из списка несинхронизированных прочитанных дней
    func removeUnsyncedReadInfopostDay(_ day: Int) {
        var days = unsyncedReadInfopostDays
        days.removeAll { $0 == day }
        unsyncedReadInfopostDays = days
    }

    /// Устанавливает весь список ID избранных инфопостов
    func setFavoriteInfopostIds(_ ids: [String]) {
        favoriteInfopostIds = ids
    }

    /// Устанавливает весь список прочитанных дней
    func setReadInfopostDays(_ days: [Int]) {
        readInfopostDays = days
    }

    /// Устанавливает весь список несинхронизированных прочитанных дней
    func setUnsyncedReadInfopostDays(_ days: [Int]) {
        unsyncedReadInfopostDays = days
    }
}
