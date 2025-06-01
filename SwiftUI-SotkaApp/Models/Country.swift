import Foundation
import SwiftData

@Model
final class Country {
    @Attribute(.unique) var id: String
    var name: String
    var cities: [City]

    init(id: String = UUID().uuidString, name: String = "", cities: [City] = []) {
        self.id = id
        self.name = name
        self.cities = cities
    }
}
