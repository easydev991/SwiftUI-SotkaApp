import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct JournalSectionBuilderTests {
    @Test("Для 100 дней возвращаются только базовые секции")
    func buildsBaseSectionsForOneHundredDays() {
        let sections = JournalSectionsBuilder.make(totalDays: 100, sortOrder: .forward)

        #expect(sections.count == 4)
        #expect(sections[0].days == Array(1 ... 49))
        #expect(sections[1].days == Array(50 ... 91))
        #expect(sections[2].days == Array(92 ... 98))
        #expect(sections[3].days == Array(99 ... 100))
    }

    @Test("Для 200 дней добавляется extended-секция 101...200")
    func addsExtendedSectionForTwoHundredDays() throws {
        let sections = JournalSectionsBuilder.make(totalDays: 200, sortOrder: .forward)
        let lastSection = try #require(sections.last)

        #expect(sections.count == 5)
        #expect(lastSection.days == Array(101 ... 200))
    }

    @Test("Обратная сортировка разворачивает порядок секций")
    func reversesSectionsForReverseSortOrder() throws {
        let sections = JournalSectionsBuilder.make(totalDays: 300, sortOrder: .reverse)
        let firstSection = try #require(sections.first)
        let lastSection = try #require(sections.last)

        #expect(firstSection.days == Array((201 ... 300).reversed()))
        #expect(lastSection.days == Array((1 ... 49).reversed()))
    }
}
