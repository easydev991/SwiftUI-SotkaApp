//
//  User.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 16.05.2025.
//

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
    var cityID: Int?
    var countryID: Int?
    var genderCode: Int?
    var birthDateIsoString: String?
    
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
        self.cityID = cityID
        self.countryID = countryID
        self.genderCode = genderCode
        self.birthDateIsoString = birthDateIsoString
    }

    convenience init(from response: UserResponse) {
        self.init(
            id: response.id,
            userName: response.userName,
            fullName: response.fullName,
            email: response.email,
            imageStringURL: response.imageStringURL,
            cityID: response.cityID,
            countryID: response.countryID,
            genderCode: response.genderCode,
            birthDateIsoString: response.birthDateIsoString
        )
    }
}

extension User {
    var avatarUrl: URL? {
        imageStringURL.queryAllowedURL
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
}

private extension User {
    var birthDate: Date {
        DateFormatterService.dateFromString(birthDateIsoString, format: .isoShortDate)
    }
    
    var genderString: String {
        guard let genderCode, let gender = Gender(genderCode) else { return "" }
        return gender.description
    }
    
    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 0
    }
}
