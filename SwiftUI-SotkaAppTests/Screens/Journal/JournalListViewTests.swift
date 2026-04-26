import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
struct JournalListPaginationTests {
    @Test("Список строит диапазон дней до totalDays для авторизованного пользователя")
    func buildsSectionsUpToTotalDays() throws {
        let content = JournalListPagination.makeContent(
            totalDays: 300,
            sortOrder: .forward,
            selectedPage: 0
        )
        let allDays = content.sections.flatMap(\.days)
        let firstDay = try #require(allDays.first)
        let lastDay = try #require(allDays.last)

        #expect(!content.shouldRenderFlatPage)
        #expect(content.flatDays.isEmpty)
        #expect(firstDay == 1)
        #expect(lastDay == 100)
        #expect(allDays.count == 100)
    }

    @Test("Без продлений диапазон ограничен 100 днями")
    func keepsBaseRangeWithoutExtensions() {
        let content = JournalListPagination.makeContent(
            totalDays: 100,
            sortOrder: .forward,
            selectedPage: 0
        )
        let allDays = content.sections.flatMap(\.days)

        #expect(!content.shouldRenderFlatPage)
        #expect(content.flatDays.isEmpty)
        #expect(allDays == Array(1 ... 100))
    }

    @Test("На странице 101-200 список не делится на секции и показывает 100 дней по порядку")
    func buildsFlatDaysForFirstExtendedPage() {
        let page = 1
        let content = JournalListPagination.makeContent(
            totalDays: 300,
            sortOrder: .forward,
            selectedPage: page
        )
        let flatDays = content.flatDays
        let firstDay = flatDays.first
        let lastDay = flatDays.last
        let count = flatDays.count

        #expect(content.shouldRenderFlatPage)
        #expect(content.sections.isEmpty)
        #expect(firstDay == 101)
        #expect(lastDay == 200)
        #expect(count == 100)
    }

    @Test("Для server-only продлений список покрывает диапазон 1...300")
    func buildsFlatDaysForSecondExtendedPage() {
        let baseContent = JournalListPagination.makeContent(
            totalDays: 300,
            sortOrder: .forward,
            selectedPage: 0
        )
        let firstExtendedContent = JournalListPagination.makeContent(
            totalDays: 300,
            sortOrder: .forward,
            selectedPage: 1
        )
        let secondExtendedContent = JournalListPagination.makeContent(
            totalDays: 300,
            sortOrder: .forward,
            selectedPage: 2
        )
        let baseAllDays = baseContent.sections.flatMap(\.days)
        let firstExtendedDays = firstExtendedContent.flatDays
        let secondExtendedDays = secondExtendedContent.flatDays

        #expect(baseAllDays.first == 1)
        #expect(baseAllDays.last == 100)
        #expect(firstExtendedDays.first == 101)
        #expect(firstExtendedDays.last == 200)
        #expect(secondExtendedDays.first == 201)
        #expect(secondExtendedDays.last == 300)
    }

    @Test("На последней неполной странице список ограничен totalDays")
    func buildsFlatDaysForPartialLastPage() {
        let page = 2
        let content = JournalListPagination.makeContent(
            totalDays: 250,
            sortOrder: .forward,
            selectedPage: page
        )
        let flatDays = content.flatDays
        let firstDay = flatDays.first
        let lastDay = flatDays.last
        let count = flatDays.count

        #expect(content.shouldRenderFlatPage)
        #expect(content.sections.isEmpty)
        #expect(firstDay == 201)
        #expect(lastDay == 250)
        #expect(count == 50)
    }

    @Test("Для базовой страницы плоский список отсутствует")
    func doesNotBuildFlatDaysForBasePage() {
        let content = JournalListPagination.makeContent(
            totalDays: 300,
            sortOrder: .forward,
            selectedPage: 0
        )
        let isEmpty = content.flatDays.isEmpty

        #expect(!content.shouldRenderFlatPage)
        #expect(!content.sections.isEmpty)
        #expect(isEmpty)
    }

    @Test("При totalDays <= 100 плоский список не строится даже для selectedPage > 0")
    func doesNotBuildFlatDaysWhenProgramNotExtended() {
        let content = JournalListPagination.makeContent(
            totalDays: 100,
            sortOrder: .forward,
            selectedPage: 1
        )
        let isEmpty = content.flatDays.isEmpty

        #expect(!content.shouldRenderFlatPage)
        #expect(!content.sections.isEmpty)
        #expect(isEmpty)
    }

    @Test("На странице 101-200 работает сортировка по убыванию")
    func buildsFlatDaysForFirstExtendedPageInReverseOrder() {
        let page = 1
        let content = JournalListPagination.makeContent(
            totalDays: 300,
            sortOrder: .reverse,
            selectedPage: page
        )
        let flatDays = content.flatDays
        let firstDay = flatDays.first
        let lastDay = flatDays.last
        let count = flatDays.count

        #expect(content.shouldRenderFlatPage)
        #expect(content.sections.isEmpty)
        #expect(firstDay == 200)
        #expect(lastDay == 101)
        #expect(count == 100)
    }

    @Test("Дни выше currentDay считаются disabled")
    func disablesDaysAboveCurrentDay() {
        let dayBeforeCurrent = JournalGridPagination.isDayEnabled(day: 120, currentDay: 130)
        let dayEqualCurrent = JournalGridPagination.isDayEnabled(day: 130, currentDay: 130)
        let dayAfterCurrent = JournalGridPagination.isDayEnabled(day: 131, currentDay: 130)

        #expect(dayBeforeCurrent)
        #expect(dayEqualCurrent)
        #expect(!dayAfterCurrent)
    }
}
