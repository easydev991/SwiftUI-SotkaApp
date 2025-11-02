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

    /// ID избранных инфопостов
    var favoriteInfopostIds: [String] = []

    /// Синхронизированные прочитанные дни инфопостов
    var readInfopostDays: [Int] = []

    /// Несинхронизированные прочитанные дни инфопостов
    var unsyncedReadInfopostDays: [Int] = []

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

    /// Словарь активностей по номеру дня для быстрого поиска
    var activitiesByDay: [Int: DayActivity] {
        Dictionary(dayActivities.map { ($0.day, $0) }, uniquingKeysWith: { $1 })
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
