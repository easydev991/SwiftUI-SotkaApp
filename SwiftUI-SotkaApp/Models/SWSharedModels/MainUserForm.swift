import Foundation
import SWUtils

/// Форма для регистрации или изменения данных профиля
struct MainUserForm: Codable, Equatable {
    var userName, fullName, email, password: String
    var birthDate: Date
    var genderCode: Int
    var countryId: String
    var countryName: String
    var cityId: String
    var cityName: String

    init(
        userName: String,
        fullName: String,
        email: String,
        password: String,
        birthDate: Date,
        gender: Int,
        countryId: String = "",
        countryName: String = "",
        cityId: String = "",
        cityName: String = ""
    ) {
        self.userName = userName
        self.fullName = fullName
        self.email = email
        self.password = password
        self.birthDate = birthDate
        self.countryId = countryId
        self.countryName = countryName
        self.cityId = cityId
        self.cityName = cityName
        self.genderCode = gender
    }

    init(_ user: User) {
        self.init(
            userName: user.userName ?? "",
            fullName: user.fullName ?? "",
            email: user.email ?? "",
            password: "",
            birthDate: user.birthDate,
            gender: user.genderCode ?? 0,
            countryId: (user.countryId ?? 0).description,
            cityId: (user.cityId ?? 0).description
        )
    }
}

extension MainUserForm {
    static let preview = MainUserForm(
        userName: "demo",
        fullName: "Demo User",
        email: "demo@mail.com",
        password: "",
        birthDate: Date(timeIntervalSince1970: 0),
        gender: 0
    )
}

extension MainUserForm {
    enum Placeholder {
        case userName
        case fullname
        case email
        case password
        case birthDate
        case country
        case city
        case gender

        var localizedString: String {
            switch self {
            case .userName: String(localized: .placeholderLogin)
            case .fullname: String(localized: .placeholderName)
            case .email: String(localized: .placeholderEmail)
            case .password: String(localized: .placeholderPassword)
            case .birthDate: String(localized: .placeholderBirthDate)
            case .country: String(localized: .placeholderCountry)
            case .city: String(localized: .placeholderCity)
            case .gender: String(localized: .placeholderGender)
            }
        }
    }

    var genderString: String {
        (Gender(genderCode) ?? .unspecified).affiliation
    }

    func placeholder(_ element: Placeholder) -> String {
        element.localizedString
    }

    /// Пример: "1990-08-12T00:00:00.000Z"
    var birthDateIsoString: String {
        DateFormatterService.stringFromFullDate(birthDate)
    }

    /// Нужно ли обновить форму при появлении экрана
    ///
    /// При появлении экрана мы не знаем страну/город пользователя,
    /// знаем только идентификаторы - их и сохраняем сразу,
    /// а название сохраняем в `onAppear`
    var shouldUpdateOnAppear: Bool {
        countryName.isEmpty || cityName.isEmpty
    }

    /// Параметры для запроса редактирования профиля
    var requestParameters: [String: String] {
        [
            "name": userName,
            "fullname": fullName,
            "email": email,
            "gender": genderCode.description,
            "country_id": countryId,
            "city_id": cityId,
            "birth_date": birthDateIsoString
        ]
    }
}
