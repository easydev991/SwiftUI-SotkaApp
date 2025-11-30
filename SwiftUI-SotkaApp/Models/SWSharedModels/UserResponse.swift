import Foundation
import SWUtils

struct UserResponse: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name, fullname, email, image: String?
    let cityId, countryId, gender: Int?
    /// Дата рождения в формате ISO short date (например, "1990-11-25")
    let birthDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullname
        case email
        case image
        case cityId
        case countryId
        case gender
        case birthDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.fullname = try container.decodeIfPresent(String.self, forKey: .fullname)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.birthDate = try? container.decodeIfPresent(Date.self, forKey: .birthDate)
        self.id = try container.decodeIntOrString(.id)
        self.cityId = container.decodeIntOrStringIfPresent(.cityId)
        self.countryId = container.decodeIntOrStringIfPresent(.countryId)
        self.gender = container.decodeIntOrStringIfPresent(.gender)
    }

    init(
        id: Int,
        name: String? = nil,
        fullname: String? = nil,
        email: String? = nil,
        image: String? = nil,
        cityId: Int? = nil,
        countryId: Int? = nil,
        gender: Int? = nil,
        birthDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.fullname = fullname
        self.email = email
        self.image = image
        self.cityId = cityId
        self.countryId = countryId
        self.gender = gender
        self.birthDate = birthDate
    }
}

extension UserResponse {
    /// Строковое представление даты рождения в формате ISO short date
    var birthDateIsoString: String? {
        birthDate.map {
            DateFormatterService.stringFromFullDate($0, format: .isoShortDate, timeZone: TimeZone(secondsFromGMT: 0), iso: false)
        }
    }
}
