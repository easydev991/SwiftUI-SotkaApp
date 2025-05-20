//
//  UserResponse+.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 20.05.2025.
//

#if DEBUG
extension UserResponse {
    static let preview = Self(
        id: 280084,
        userName: "DemoUserName",
        fullName: "DemoFullName",
        email: "demo_mail@mail.ru",
        imageStringURL: "https://workout.su/uploads/avatars/2023/01/2023-01-06-16-01-16-qyj.png",
        cityID: 1,
        countryID: 17,
        genderCode: 0,
        birthDateIsoString: "1990-10-10"
    )
}
#endif
