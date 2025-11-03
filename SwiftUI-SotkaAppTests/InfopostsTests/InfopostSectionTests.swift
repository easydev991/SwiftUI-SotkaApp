import Foundation
import SwiftUI
@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    struct InfopostSectionTests {
        // MARK: - Тесты свойства days

        @Test("Должен возвращать дни 1-49 для базовой секции")
        func daysReturnsCorrectRangeForBase() {
            let section = InfopostSection.base
            let days = section.days
            #expect(days == Array(1 ... 49))
            #expect(days.count == 49)
        }

        @Test("Должен возвращать дни 50-91 для продвинутой секции")
        func daysReturnsCorrectRangeForAdvanced() {
            let section = InfopostSection.advanced
            let days = section.days
            #expect(days == Array(50 ... 91))
            #expect(days.count == 42)
        }

        @Test("Должен возвращать дни 92-98 для турбо секции")
        func daysReturnsCorrectRangeForTurbo() {
            let section = InfopostSection.turbo
            let days = section.days
            #expect(days == Array(92 ... 98))
            #expect(days.count == 7)
        }

        @Test("Должен возвращать дни 99-100 для завершающей секции")
        func daysReturnsCorrectRangeForConclusion() {
            let section = InfopostSection.conclusion
            let days = section.days
            #expect(days == Array(99 ... 100))
            #expect(days.count == 2)
        }

        @Test("Должен возвращать пустой массив для подготовительной секции")
        func daysReturnsEmptyArrayForPreparation() {
            let section = InfopostSection.preparation
            let days = section.days
            #expect(days.isEmpty)
        }

        @Test("Должен возвращать правильные дни для всех секций", arguments: [
            (InfopostSection.base, Array(1 ... 49)),
            (InfopostSection.advanced, Array(50 ... 91)),
            (InfopostSection.turbo, Array(92 ... 98)),
            (InfopostSection.conclusion, Array(99 ... 100)),
            (InfopostSection.preparation, [Int]())
        ])
        func daysReturnsCorrectRangeForAllSections(section: InfopostSection, expectedDays: [Int]) {
            let days = section.days
            #expect(days == expectedDays)
        }

        // MARK: - Тесты свойства journalSections

        @Test("Должен возвращать все секции кроме подготовительной")
        func journalSectionsReturnsAllSectionsExceptPreparation() {
            let sections = InfopostSection.journalSections
            #expect(sections.count == 4)
            #expect(sections.contains(.base))
            #expect(sections.contains(.advanced))
            #expect(sections.contains(.turbo))
            #expect(sections.contains(.conclusion))
            #expect(!sections.contains(.preparation))
        }

        @Test("Должен возвращать секции в правильном порядке")
        func journalSectionsReturnsSectionsInCorrectOrder() {
            let sections = InfopostSection.journalSections
            #expect(sections[0] == .base)
            #expect(sections[1] == .advanced)
            #expect(sections[2] == .turbo)
            #expect(sections[3] == .conclusion)
        }

        @Test("Должен возвращать только секции с днями")
        func journalSectionsReturnsOnlySectionsWithDays() {
            let sections = InfopostSection.journalSections
            for section in sections {
                #expect(!section.days.isEmpty)
            }
        }

        // MARK: - Тесты метода section(for filename:)

        @Test("Должен возвращать правильную секцию для файлов с префиксом d", arguments: [
            ("d1", InfopostSection.base),
            ("d25", InfopostSection.base),
            ("d49", InfopostSection.base),
            ("d50", InfopostSection.advanced),
            ("d75", InfopostSection.advanced),
            ("d91", InfopostSection.advanced),
            ("d92", InfopostSection.turbo),
            ("d95", InfopostSection.turbo),
            ("d98", InfopostSection.turbo),
            ("d99", InfopostSection.conclusion),
            ("d100", InfopostSection.conclusion)
        ])
        func sectionForFilenameReturnsCorrectSectionForDayFiles(filename: String, expectedSection: InfopostSection) {
            let section = InfopostSection.section(for: filename)
            #expect(section == expectedSection)
        }

        @Test("Должен возвращать preparation для специальных файлов", arguments: ["aims", "organiz", "d0-women"])
        func sectionForFilenameReturnsPreparationForSpecialFiles(filename: String) {
            let section = InfopostSection.section(for: filename)
            #expect(section == .preparation)
        }

        @Test("Должен возвращать preparation для файлов с d без числа")
        func sectionForFilenameReturnsPreparationForDFilesWithoutNumber() {
            let section = InfopostSection.section(for: "dabc")
            #expect(section == .preparation)
        }

        @Test("Должен возвращать preparation для неизвестных файлов", arguments: ["about", "unknown", "test", "other"])
        func sectionForFilenameReturnsPreparationForUnknownFiles(filename: String) {
            let section = InfopostSection.section(for: filename)
            #expect(section == .preparation)
        }

        @Test("Должен возвращать preparation для пустой строки")
        func sectionForFilenameReturnsPreparationForEmptyString() {
            let section = InfopostSection.section(for: "")
            #expect(section == .preparation)
        }

        // MARK: - Тесты метода sectionsSortedBy(sortOrder:)

        @Test("Должен возвращать секции в прямом порядке для .forward")
        func sortedJournalSectionsReturnsForwardOrderForForward() {
            let sections = InfopostSection.sectionsSortedBy(.forward)
            #expect(sections.count == 4)
            #expect(sections[0] == .base)
            #expect(sections[1] == .advanced)
            #expect(sections[2] == .turbo)
            #expect(sections[3] == .conclusion)
        }

        @Test("Должен возвращать секции в обратном порядке для .reverse")
        func sortedJournalSectionsReturnsReverseOrderForReverse() {
            let sections = InfopostSection.sectionsSortedBy(.reverse)
            #expect(sections.count == 4)
            #expect(sections[0] == .conclusion)
            #expect(sections[1] == .turbo)
            #expect(sections[2] == .advanced)
            #expect(sections[3] == .base)
        }

        @Test("Должен возвращать все секции дневника в обоих режимах сортировки")
        func sortedJournalSectionsReturnsAllSectionsInBothSortOrders() {
            let forwardSections = InfopostSection.sectionsSortedBy(.forward)
            let reverseSections = InfopostSection.sectionsSortedBy(.reverse)

            #expect(Set(forwardSections) == Set(reverseSections))
            #expect(forwardSections.count == 4)
            #expect(reverseSections.count == 4)
        }

        // MARK: - Тесты метода sortedDays(sortOrder:)

        @Test("Должен возвращать дни в прямом порядке для .forward")
        func sortedDaysReturnsForwardOrderForForward() {
            let section = InfopostSection.base
            let sortedDays = section.daysSortedBy(.forward)
            #expect(sortedDays == Array(1 ... 49))
            #expect(sortedDays.first == 1)
            #expect(sortedDays.last == 49)
        }

        @Test("Должен возвращать дни в обратном порядке для .reverse")
        func sortedDaysReturnsReverseOrderForReverse() {
            let section = InfopostSection.base
            let sortedDays = section.daysSortedBy(.reverse)
            #expect(sortedDays == Array(1 ... 49).reversed())
            #expect(sortedDays.first == 49)
            #expect(sortedDays.last == 1)
        }

        @Test("Должен работать с продвинутой секцией для обоих порядков")
        func sortedDaysWorksWithAdvancedSectionForBothOrders() {
            let section = InfopostSection.advanced
            let forwardDays = section.daysSortedBy(.forward)
            let reverseDays = section.daysSortedBy(.reverse)

            #expect(forwardDays == Array(50 ... 91))
            #expect(reverseDays == Array(50 ... 91).reversed())
            #expect(forwardDays.first == 50)
            #expect(forwardDays.last == 91)
            #expect(reverseDays.first == 91)
            #expect(reverseDays.last == 50)
        }

        @Test("Должен работать с турбо секцией для обоих порядков")
        func sortedDaysWorksWithTurboSectionForBothOrders() {
            let section = InfopostSection.turbo
            let forwardDays = section.daysSortedBy(.forward)
            let reverseDays = section.daysSortedBy(.reverse)

            #expect(forwardDays == Array(92 ... 98))
            #expect(reverseDays == Array(92 ... 98).reversed())
            #expect(forwardDays.first == 92)
            #expect(forwardDays.last == 98)
            #expect(reverseDays.first == 98)
            #expect(reverseDays.last == 92)
        }

        @Test("Должен работать с завершающей секцией для обоих порядков")
        func sortedDaysWorksWithConclusionSectionForBothOrders() {
            let section = InfopostSection.conclusion
            let forwardDays = section.daysSortedBy(.forward)
            let reverseDays = section.daysSortedBy(.reverse)

            #expect(forwardDays == Array(99 ... 100))
            #expect(reverseDays == Array(99 ... 100).reversed())
            #expect(forwardDays.first == 99)
            #expect(forwardDays.last == 100)
            #expect(reverseDays.first == 100)
            #expect(reverseDays.last == 99)
        }

        @Test("Должен возвращать пустой массив для подготовительной секции", arguments: [SortOrder.forward, SortOrder.reverse])
        func sortedDaysReturnsEmptyArrayForPreparationSection(sortOrder: SortOrder) {
            let section = InfopostSection.preparation
            let sortedDays = section.daysSortedBy(sortOrder)
            #expect(sortedDays.isEmpty)
        }

        @Test("Должен возвращать те же дни в разных порядках для всех секций")
        func sortedDaysReturnsSameDaysInDifferentOrdersForAllSections() {
            for section in InfopostSection.allCases {
                let forwardDays = section.daysSortedBy(.forward)
                let reverseDays = section.daysSortedBy(.reverse)

                #expect(Set(forwardDays) == Set(reverseDays))
                #expect(forwardDays.count == reverseDays.count)
            }
        }
    }
}
