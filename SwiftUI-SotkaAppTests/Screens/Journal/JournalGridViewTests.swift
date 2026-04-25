import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
struct JournalGridViewTests {
    @Test("Контролы пагинации показываются только при totalDays > 100")
    func showsPaginationControlsOnlyWhenExtended() {
        let forBaseProgram = JournalGridPagination.shouldShowPaginationControls(totalDays: 100)
        let forFirstExtendedDay = JournalGridPagination.shouldShowPaginationControls(totalDays: 101)
        let forTwoHundredDays = JournalGridPagination.shouldShowPaginationControls(totalDays: 200)

        #expect(!forBaseProgram)
        #expect(forFirstExtendedDay)
        #expect(forTwoHundredDays)
    }

    @Test("PageCount корректно считается для 100/200/250")
    func calculatesPageCount() {
        #expect(JournalGridPagination.pageCount(totalDays: 100) == 1)
        #expect(JournalGridPagination.pageCount(totalDays: 200) == 2)
        #expect(JournalGridPagination.pageCount(totalDays: 250) == 3)
    }

    @Test("Формула page 0 использует сумму строк предыдущих секций")
    func mapsDayForFirstPageBySectionsPrefixSum() {
        let pageZeroSections = JournalSectionsBuilder.make(totalDays: 100, sortOrder: .forward)
        let dayForFirstSection = pageZeroSections[0].days[0]
        let dayForSecondSection = pageZeroSections[1].days[0]
        let dayForConclusionSection = pageZeroSections[3].days[0]

        #expect(dayForFirstSection == 1)
        #expect(dayForSecondSection == 50)
        #expect(dayForConclusionSection == 99)
    }

    @Test("Формула page > 0: page 1 row 0 даёт день 101")
    func mapsDayForExtendedPages() throws {
        let page = 1
        let sections = JournalGridPagination.makeSections(totalDays: 200, page: page)
        let section = try #require(sections.first)

        #expect(section.days[0] == 101)
        #expect(section.days[99] == 200)
    }

    @Test("Для server-only продлений grid покрывает диапазон 1...300 по страницам")
    func buildsSectionsForServerOnlyThreeHundredDays() throws {
        let baseSections = JournalGridPagination.makeSections(totalDays: 300, page: 0)
        let firstExtendedSections = JournalGridPagination.makeSections(totalDays: 300, page: 1)
        let secondExtendedSections = JournalGridPagination.makeSections(totalDays: 300, page: 2)
        let firstBaseSection = try #require(baseSections.first)
        let lastBaseSection = try #require(baseSections.last)
        let firstExtendedSection = try #require(firstExtendedSections.first)
        let secondExtendedSection = try #require(secondExtendedSections.first)

        #expect(firstBaseSection.days.first == 1)
        #expect(lastBaseSection.days.last == 100)
        #expect(firstExtendedSection.days.first == 101)
        #expect(firstExtendedSection.days.last == 200)
        #expect(secondExtendedSection.days.first == 201)
        #expect(secondExtendedSection.days.last == 300)
    }

    @Test("Для offline-only без продлений grid ограничен диапазоном 1...100")
    func keepsBaseRangeForOfflineOnlyWithoutExtensions() {
        let shouldShowControls = JournalGridPagination.shouldShowPaginationControls(totalDays: 100)
        let pageCount = JournalGridPagination.pageCount(totalDays: 100)
        let clampedSections = JournalGridPagination.makeSections(totalDays: 100, page: 5)
        let allDays = clampedSections.flatMap(\.days)

        #expect(!shouldShowControls)
        #expect(pageCount == 1)
        #expect(allDays.first == 1)
        #expect(allDays.last == 100)
    }

    @Test("В grid дни выше currentDay считаются disabled")
    func disablesDaysAboveCurrentDay() {
        let dayBeforeCurrent = JournalGridPagination.isDayEnabled(day: 120, currentDay: 130)
        let dayEqualCurrent = JournalGridPagination.isDayEnabled(day: 130, currentDay: 130)
        let dayAfterCurrent = JournalGridPagination.isDayEnabled(day: 131, currentDay: 130)

        #expect(dayBeforeCurrent)
        #expect(dayEqualCurrent)
        #expect(!dayAfterCurrent)
    }
}
