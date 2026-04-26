import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    struct YouTubeLinkNormalizerTests {
        private let normalizer = YouTubeLinkNormalizer()

        @Test
        func normalizesEmbedURL() {
            let result = normalizer.normalizedWatchURL(from: "https://www.youtube.com/embed/OM0m9CEjq2Y")
            #expect(result?.absoluteString == "https://www.youtube.com/watch?v=OM0m9CEjq2Y")
        }

        @Test
        func normalizesWatchURL() {
            let result = normalizer.normalizedWatchURL(from: "https://www.youtube.com/watch?v=OM0m9CEjq2Y&t=10s")
            #expect(result?.absoluteString == "https://www.youtube.com/watch?v=OM0m9CEjq2Y")
        }

        @Test
        func normalizesShortURL() {
            let result = normalizer.normalizedWatchURL(from: "https://youtu.be/OM0m9CEjq2Y")
            #expect(result?.absoluteString == "https://www.youtube.com/watch?v=OM0m9CEjq2Y")
        }

        @Test
        func normalizesURLWithoutWWW() {
            let result = normalizer.normalizedWatchURL(from: "https://youtube.com/watch?v=OM0m9CEjq2Y")
            #expect(result?.absoluteString == "https://www.youtube.com/watch?v=OM0m9CEjq2Y")
        }

        @Test
        func returnsNilForNonYouTubeURL() {
            let result = normalizer.normalizedWatchURL(from: "https://example.com/video.mp4")
            #expect(result == nil)
        }
    }
}
