import Foundation
import SwiftUI

struct JournalSection: Identifiable, Hashable {
    let title: String
    let days: [Int]

    var id: String {
        "\(title)-\(days.first ?? 0)-\(days.last ?? 0)"
    }
}

enum JournalSectionsBuilder {
    static func make(totalDays: Int, sortOrder: SortOrder) -> [JournalSection] {
        let normalizedTotalDays = max(1, totalDays)
        var sections = makeBaseSections()

        if normalizedTotalDays > DayCalculator.baseProgramDays {
            sections += makeExtendedSections(totalDays: normalizedTotalDays)
        }

        if sortOrder == .reverse {
            return sections.reversed().map { section in
                JournalSection(
                    title: section.title,
                    days: section.days.reversed()
                )
            }
        }

        return sections
    }
}

private extension JournalSectionsBuilder {
    static func makeBaseSections() -> [JournalSection] {
        [
            JournalSection(
                title: InfopostSection.base.localizedTitle,
                days: InfopostSection.base.days
            ),
            JournalSection(
                title: InfopostSection.advanced.localizedTitle,
                days: InfopostSection.advanced.days
            ),
            JournalSection(
                title: InfopostSection.turbo.localizedTitle,
                days: InfopostSection.turbo.days
            ),
            JournalSection(
                title: InfopostSection.conclusion.localizedTitle,
                days: InfopostSection.conclusion.days
            )
        ]
    }

    static func makeExtendedSections(totalDays: Int) -> [JournalSection] {
        var sections: [JournalSection] = []
        var startDay = DayCalculator.baseProgramDays + 1

        while startDay <= totalDays {
            let endDay = min(startDay + DayCalculator.extensionBlockDays - 1, totalDays)
            sections.append(
                JournalSection(
                    title: "\(startDay)-\(endDay)",
                    days: Array(startDay ... endDay)
                )
            )
            startDay += DayCalculator.extensionBlockDays
        }

        return sections
    }
}
