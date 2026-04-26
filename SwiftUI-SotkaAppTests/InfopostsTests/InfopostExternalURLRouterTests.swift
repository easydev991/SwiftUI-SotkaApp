import Foundation
@testable import SwiftUI_SotkaApp
import Testing
import WebKit

extension AllInfopostsTests {
    struct InfopostExternalURLRouterTests {
        private let router = InfopostExternalURLRouter()

        @Test("Роутер возвращает открытие внешней ссылки для валидной sotka YouTube-ссылки")
        func routerReturnsOpenExternallyForValidSotkaYouTubeLink() throws {
            let url = try #require(URL(string: "sotka://youtube?url=https%253A%252F%252Fwww.youtube.com%252Fwatch%253Fv%253DOM0m9CEjq2Y"))
            let decision = router.decision(for: url)

            guard case let .openExternally(externalURL) = decision else {
                Issue.record("Ожидали решение openExternally")
                return
            }

            #expect(externalURL.absoluteString == "https://www.youtube.com/watch?v=OM0m9CEjq2Y")
        }

        @Test("Роутер отменяет навигацию для невалидного payload в sotka-ссылке")
        func routerReturnsCancelForInvalidSotkaPayload() throws {
            let url = try #require(URL(string: "sotka://youtube?url=not_a_url"))
            let decision = router.decision(for: url)
            #expect(decision == .cancel)
        }

        @Test("Роутер пропускает обычные ссылки без изменения")
        func routerAllowsRegularLinks() throws {
            let url = try #require(URL(string: "https://workout.su"))
            let decision = router.decision(for: url)
            #expect(decision == .allow)
        }

        @Test("Координатор отменяет навигацию и запрашивает внешнее открытие для sotka YouTube-ссылки")
        @MainActor
        func coordinatorCancelsAndRequestsExternalOpeningForSotkaYouTubeLink() async throws {
            // Given
            var openedURL: URL?
            let coordinator = HTMLContentView.Coordinator(
                onReachedEnd: {},
                externalURLRouter: router,
                openExternalURL: { url in
                    openedURL = url
                }
            )
            let requestURL = URL(string: "sotka://youtube?url=https%253A%252F%252Fwww.youtube.com%252Fwatch%253Fv%253DOM0m9CEjq2Y")

            // When
            let policy = await coordinator.navigationPolicy(for: requestURL)

            // Then
            #expect(policy == .cancel)
            let openedExternalURL = try #require(openedURL)
            #expect(openedExternalURL.absoluteString == "https://www.youtube.com/watch?v=OM0m9CEjq2Y")
        }

        @Test("Координатор разрешает навигацию для обычной внешней ссылки")
        @MainActor
        func coordinatorAllowsRegularExternalLinks() async {
            // Given
            var openCallCount = 0
            let coordinator = HTMLContentView.Coordinator(
                onReachedEnd: {},
                externalURLRouter: router,
                openExternalURL: { _ in
                    openCallCount += 1
                }
            )

            // When
            let policy = await coordinator.navigationPolicy(for: URL(string: "https://example.com"))

            // Then
            #expect(policy == .allow)
            #expect(openCallCount == 0)
        }
    }
}
