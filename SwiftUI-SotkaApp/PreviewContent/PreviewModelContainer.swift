//
//  PreviewModelContainer.swift
//  SwiftUI-Days
//
//  Created by Oleg991 on 24.03.2024.
//

import SwiftData

enum PreviewModelContainer {
    @MainActor
    static func make(with user: User) -> ModelContainer {
        let schema = Schema([User.self, Country.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        container.mainContext.insert(user)
        let russia = CountryResponse.defaultCountry
        let country = Country(id: russia.id, name: russia.name, cities: russia.cities.map(City.init))
        container.mainContext.insert(country)
        return container
    }
}
