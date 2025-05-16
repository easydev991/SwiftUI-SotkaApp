//
//  UserResponse.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 16.05.2025.
//

import Foundation

struct UserResponse: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let userName, fullName, email, imageStringURL: String?
    let cityID, countryID, genderCode, friendsCount, journalsCount: Int?
    /// Пример: "1990-11-25"
    let birthDateIsoString: String?
    let parksCountString: String? // "0"
    
    enum CodingKeys: String, CodingKey {
        case id
        case userName = "name"
        case imageStringURL = "image"
        case cityID = "city_id"
        case countryID = "country_id"
        case genderCode = "gender"
        case birthDateIsoString = "birth_date"
        case fullName = "fullname"
        case friendsCount = "friend_count"
        case parksCountString = "area_count"
        case journalsCount = "journal_count"
        case email
    }
}
