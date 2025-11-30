#if DEBUG
import Foundation
import SWUtils

extension UserResponse {
    static let preview = Self(
        id: 280084,
        name: "DemoUserName",
        fullname: "DemoFullName",
        email: "demo_mail@mail.ru",
        image: "https://workout.su/uploads/avatars/2023/01/2023-01-06-16-01-16-qyj.png",
        cityId: 1,
        countryId: 17,
        gender: 0,
        birthDate: Calendar(identifier: .iso8601).date(from: DateComponents(year: 1990, month: 10, day: 10))
    )
}
#endif
