import Foundation
import SwiftData
import SWUtils

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
    @Relationship(deleteRule: .cascade) var progressResults: [Progress] = []

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
        let localizedAgeString = String.localizedStringWithFormat(
            NSLocalizedString("ageInYears", comment: ""),
            age
        )
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

    /// Проверяет, заполнены ли результаты для текущего дня
    func isMaximumsFilled(for currentDay: Int) -> Bool {
        let progressDay: Int
        if currentDay >= 1, currentDay <= 49 {
            progressDay = 1 // БАЗОВЫЙ блок
        } else if currentDay >= 50, currentDay <= 99 {
            progressDay = 50 // ПРОДВИНУТЫЙ блок
        } else if currentDay >= 100 {
            progressDay = 100 // Заключение
        } else {
            return true
        }

        // Проверяем, есть ли заполненные результаты для соответствующего дня
        return progressResults.contains { $0.id == progressDay && $0.isFilled }
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
