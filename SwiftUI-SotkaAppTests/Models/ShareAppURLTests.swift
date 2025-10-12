import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("ShareAppURL Tests")
struct ShareAppURLTests {
    @Test("Должен создавать URL для русской локали")
    func russianLocale() throws {
        let model = try #require(ShareAppURL(localeIdentifier: "ru_RU", appId: "123456789"))
        let expectedURL = try #require(URL(string: "https://apps.apple.com/ru/app/123456789"))

        #expect(model.url == expectedURL)
    }

    @Test("Должен создавать URL для не-русских локалей", arguments: ["en_US", "en_GB", "de_DE", "fr_FR", "es_ES", "ja_JP"])
    func nonRussianLocales(locale: String) throws {
        let model = try #require(ShareAppURL(localeIdentifier: locale, appId: "111111111"))
        let expectedURL = try #require(URL(string: "https://apps.apple.com/us/app/111111111"))

        #expect(model.url == expectedURL)
    }

    @Test("Должен обрабатывать локаль без подчеркивания")
    func localeWithoutUnderscore() throws {
        let model = try #require(ShareAppURL(localeIdentifier: "ru", appId: "222222222"))
        let expectedURL = try #require(URL(string: "https://apps.apple.com/ru/app/222222222"))

        #expect(model.url == expectedURL)
    }

    @Test("Должен возвращать nil для пустого appId")
    func emptyAppId() throws {
        let model = ShareAppURL(localeIdentifier: "ru_RU", appId: "")

        #expect(model == nil)
    }

    @Test("Должен обрабатывать специальные символы в appId")
    func specialCharactersInAppId() throws {
        let model = try #require(ShareAppURL(localeIdentifier: "en_US", appId: "app-123_test"))
        let expectedURL = try #require(URL(string: "https://apps.apple.com/us/app/app-123_test"))

        #expect(model.url == expectedURL)
    }

    @Test("Должен корректно обрабатывать пробелы в appId")
    func spacesInAppId() throws {
        let model = try #require(ShareAppURL(localeIdentifier: "ru_RU", appId: "app with spaces"))
        let expectedURL = try #require(URL(string: "https://apps.apple.com/ru/app/app%20with%20spaces"))

        #expect(model.url == expectedURL)
    }

    @Test("Должен обрабатывать множественные подчеркивания в локали")
    func multipleUnderscoresInLocale() throws {
        let model = try #require(ShareAppURL(localeIdentifier: "ru_RU_Moscow", appId: "333333333"))
        let expectedURL = try #require(URL(string: "https://apps.apple.com/ru/app/333333333"))

        #expect(model.url == expectedURL)
    }
}
