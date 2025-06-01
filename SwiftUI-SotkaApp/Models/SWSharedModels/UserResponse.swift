import Foundation

struct UserResponse: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name, fullname, email, image: String?
    let cityId, countryId, gender: Int?
    /// Пример: "1990-11-25"
    let birthDate: String?
}
