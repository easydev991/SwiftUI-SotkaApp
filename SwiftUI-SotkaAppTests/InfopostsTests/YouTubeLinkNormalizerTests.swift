import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    struct YouTubeLinkNormalizerTests {
        private let normalizer = YouTubeLinkNormalizer()

        @Test("Нормализует embed-ссылку YouTube в watch-ссылку")
        func normalizesEmbedURL() throws {
            let result = normalizer.normalizedWatchURL(from: "https://www.youtube.com/embed/OM0m9CEjq2Y")
            let normalizedURL = try #require(result)
            #expect(normalizedURL.absoluteString == "https://www.youtube.com/watch?v=OM0m9CEjq2Y")
        }

        @Test("Нормализует watch-ссылку YouTube и удаляет лишние параметры")
        func normalizesWatchURL() throws {
            let result = normalizer.normalizedWatchURL(from: "https://www.youtube.com/watch?v=OM0m9CEjq2Y&t=10s")
            let normalizedURL = try #require(result)
            #expect(normalizedURL.absoluteString == "https://www.youtube.com/watch?v=OM0m9CEjq2Y")
        }

        @Test("Нормализует короткую ссылку youtu.be в watch-ссылку")
        func normalizesShortURL() throws {
            let result = normalizer.normalizedWatchURL(from: "https://youtu.be/OM0m9CEjq2Y")
            let normalizedURL = try #require(result)
            #expect(normalizedURL.absoluteString == "https://www.youtube.com/watch?v=OM0m9CEjq2Y")
        }

        @Test("Нормализует YouTube-ссылку без www")
        func normalizesURLWithoutWWW() throws {
            let result = normalizer.normalizedWatchURL(from: "https://youtube.com/watch?v=OM0m9CEjq2Y")
            let normalizedURL = try #require(result)
            #expect(normalizedURL.absoluteString == "https://www.youtube.com/watch?v=OM0m9CEjq2Y")
        }

        @Test("Возвращает nil для ссылок не из YouTube")
        func returnsNilForNonYouTubeURL() {
            let result = normalizer.normalizedWatchURL(from: "https://example.com/video.mp4")
            #expect(result == nil)
        }
    }
}
