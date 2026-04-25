import Foundation

enum JournalListPagination {
    struct Content: Equatable {
        let shouldRenderFlatPage: Bool
        let sections: [JournalSection]
        let flatDays: [Int]
    }

    static func makeContent(totalDays: Int, sortOrder: SortOrder, selectedPage: Int) -> Content {
        guard selectedPage > 0, JournalGridPagination.shouldShowPaginationControls(totalDays: totalDays) else {
            return Content(
                shouldRenderFlatPage: false,
                sections: JournalSectionsBuilder.make(
                    totalDays: min(totalDays, DayCalculator.baseProgramDays),
                    sortOrder: sortOrder
                ),
                flatDays: []
            )
        }

        let range = JournalGridPagination.pageRange(page: selectedPage, totalDays: totalDays)
        let forwardDays = Array(range)
        let flatDays: [Int] = switch sortOrder {
        case .forward:
            forwardDays
        case .reverse:
            Array(forwardDays.reversed())
        }

        return Content(
            shouldRenderFlatPage: true,
            sections: [],
            flatDays: flatDays
        )
    }
}
