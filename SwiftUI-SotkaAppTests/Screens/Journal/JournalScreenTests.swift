import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
struct JournalScreenTests {
    @Test("Toolbar-пагинация в list скрыта при totalDays <= 100")
    func listPaginationControlsAreHiddenForBaseProgram() {
        let shouldShow = JournalScreen.shouldShowPaginationControls(
            displayMode: .list,
            totalDays: 100
        )

        #expect(!shouldShow)
    }

    @Test("Toolbar-пагинация в list показывается при totalDays > 100")
    func listPaginationControlsAreShownForExtendedProgram() {
        let shouldShow = JournalScreen.shouldShowPaginationControls(
            displayMode: .list,
            totalDays: 101
        )

        #expect(shouldShow)
    }

    @Test("Кнопка next увеличивает страницу в list в пределах диапазона")
    func nextPageInListModeMovesForward() {
        let nextPage = JournalScreen.nextPage(
            from: 0,
            totalDays: 300
        )

        #expect(nextPage == 1)
    }

    @Test("Кнопка previous уменьшает страницу в list и не уходит ниже нуля")
    func previousPageInListModeMovesBackwardAndClamps() {
        let previousFromMiddle = JournalScreen.previousPage(
            from: 2,
            totalDays: 300
        )
        let previousFromZero = JournalScreen.previousPage(
            from: 0,
            totalDays: 300
        )

        #expect(previousFromMiddle == 1)
        #expect(previousFromZero == 0)
    }
}
