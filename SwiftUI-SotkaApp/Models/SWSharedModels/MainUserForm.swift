import Foundation
import SWUtils

/// Форма для отправки при регистрации или изменении данных профиля
struct MainUserForm: Codable, Equatable, Sendable {
    var userName, fullName, email, password: String
    var birthDate: Date
    var genderCode: Int
    var country: CountryResponse
    var city: CityResponse
    var image: MediaFile?

    init(
        userName: String,
        fullName: String,
        email: String,
        password: String,
        birthDate: Date,
        gender: Int,
        country: CountryResponse,
        city: CityResponse,
        image: MediaFile? = nil
    ) {
        self.userName = userName
        self.fullName = fullName
        self.email = email
        self.password = password
        self.birthDate = birthDate
        self.country = country
        self.city = city
        self.genderCode = gender
        self.image = image
    }

    init(_ user: User) {
        self.init(
            userName: user.userName ?? "",
            fullName: user.fullName ?? "",
            email: user.email ?? "",
            password: "",
            birthDate: user.birthDate,
            gender: user.genderCode ?? 0,
            country: .init(cities: [], id: (user.countryId ?? 0).description, name: ""),
            city: .init(id: (user.cityId ?? 0).description, name: "", lat: nil, lon: nil)
        )
    }
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

    /// Готовность формы к регистрации нового пользователя
    var isReadyToRegister: Bool {
        !userName.isEmpty
            && !email.isEmpty
            && password.count >= Constants.minPasswordSize
            && genderCode != Gender.unspecified.code
            && birthDate <= Constants.minUserAge
    }

    /// Готовность формы к сохранению обновленных данных
    func isReadyToSave(comparedTo oldForm: MainUserForm) -> Bool {
        let isNewFormNotEmpty = !userName.isEmpty
            && !email.isEmpty
            && !fullName.isEmpty
            && genderCode != Gender.unspecified.code
            && birthDate <= Constants.minUserAge
        return isNewFormNotEmpty && self != oldForm
    }

    /// Нужно ли обновить форму при появлении экрана
    ///
    /// При появлении экрана мы не знаем страну/город пользователя,
    /// знаем только идентификаторы - их и сохраняем сразу,
    /// а название сохраняем в `onAppear`
    var shouldUpdateOnAppear: Bool {
        country.name.isEmpty || city.name.isEmpty
    }

    /// Параметры для запроса редактирования профиля
    var requestParameters: [String: String] {
        [
            "name": userName,
            "fullname": fullName,
            "email": email,
            "gender": genderCode.description,
            "country_id": country.id,
            "city_id": city.id,
            "birth_date": birthDateIsoString
        ]
    }
}
