import Foundation
import SwiftData

@Model
final class Country {
    @Attribute(.unique) var id: String
    var name: String

    init(id: String = UUID().uuidString, name: String = "") {
        self.id = id
        self.name = name
    }

    static func makeDefaultCountry() -> Country {
        Country(id: "ru", name: "Россия")
    }
}
