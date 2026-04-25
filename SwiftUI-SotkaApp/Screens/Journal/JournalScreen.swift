import SWDesignSystem
import SwiftUI

struct JournalScreen: View {
    @Environment(\.analyticsService) private var analytics
    @Environment(StatusManager.self) private var statusManager
    @AppStorage(SortOrder.appStorageKey) private var sortOrder = SortOrder.forward
    @AppStorage(DisplayMode.appStorageKey) private var displayMode = DisplayMode.grid
    @State private var selectedPage = 0
    let user: User

    private var totalDays: Int {
        statusManager.currentDayCalculator?.totalDays ?? DayCalculator.baseProgramDays
    }

    private var pageCount: Int {
        JournalGridPagination.pageCount(totalDays: totalDays)
    }

    private var clampedSelectedPage: Int {
        min(max(0, selectedPage), pageCount - 1)
    }

    private var selectedPageRange: ClosedRange<Int> {
        JournalGridPagination.pageRange(page: clampedSelectedPage, totalDays: totalDays)
    }

    private var selectedPageSections: [JournalSection] {
        JournalGridPagination.makeSections(totalDays: totalDays, page: clampedSelectedPage)
    }

    private var shouldShowPaginationControls: Bool {
        Self.shouldShowPaginationControls(displayMode: displayMode, totalDays: totalDays)
    }

    var body: some View {
        VStack(spacing: 12) {
            switch displayMode {
            case .list:
                JournalListView(
                    activitiesByDay: user.activitiesByDay,
                    totalDays: totalDays,
                    sortOrder: sortOrder,
                    selectedPage: clampedSelectedPage
                )
            case .grid:
                JournalGridView(
                    activitiesByDay: user.activitiesByDay,
                    selectedPage: clampedSelectedPage,
                    pageDaysRange: selectedPageRange,
                    pageSections: selectedPageSections
                )
            }
        }
        .toolbar {
            if displayMode == .list {
                ToolbarItem {
                    sortButton
                }
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.fixed)
                }
            }
            if shouldShowPaginationControls {
                ToolbarItem {
                    pagePicker
                }
                ToolbarItem {
                    previousPageButton
                }
                ToolbarItem {
                    nextPageButton
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                displayModeButton
            }
        }
        .animation(.default, value: displayMode)
        .background(Color.swBackground)
        .navigationTitle(.journal)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen(.journal)
        .onAppear {
            selectedPage = JournalPagePersistence.restoreSelectedPage(totalDays: totalDays)
        }
        .onChange(of: sortOrder) { _, _ in
            analytics.log(
                .userAction(action: .selectJournalSort(newSortOrder: "\(sortOrder.rawValue)"))
            )
        }
        .onChange(of: displayMode) { _, _ in
            analytics.log(.userAction(action: .selectJournalDisplayMode(newDisplayMode: "\(displayMode.id)")))
        }
        .onChange(of: totalDays) { _, _ in
            let clampedPage = JournalPagePersistence.clamp(page: selectedPage, totalDays: totalDays)
            selectedPage = clampedPage
            JournalPagePersistence.saveSelectedPage(clampedPage, totalDays: totalDays)
        }
        .onChange(of: selectedPage) { _, newPage in
            let clampedPage = JournalPagePersistence.clamp(page: newPage, totalDays: totalDays)
            if clampedPage != newPage {
                selectedPage = clampedPage
                return
            }
            JournalPagePersistence.saveSelectedPage(clampedPage, totalDays: totalDays)
        }
    }
}

extension JournalScreen {
    enum DisplayMode: Int, Equatable, CaseIterable, Identifiable {
        var id: Int {
            rawValue
        }

        case list
        case grid

        var localizedTitle: String {
            switch self {
            case .list: String(localized: .journalDisplayModeList)
            case .grid: String(localized: .journalDisplayModeGrid)
            }
        }

        static let appStorageKey = "JournalDisplayMode"
    }
}

private extension JournalScreen {
    var sortButton: some View {
        Menu {
            Picker(.journalListSortButtonLabel, selection: $sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) {
                    Text($0.localizedTitle).tag($0)
                }
            }
        } label: {
            Label(.journalListSortButtonLabel, systemImage: "arrow.up.arrow.down")
        }
        .accessibilityValue(sortOrder.localizedTitle)
    }

    var displayModeButton: some View {
        Menu {
            Picker(.journalDisplayMode, selection: $displayMode) {
                ForEach(DisplayMode.allCases) {
                    Text($0.localizedTitle).tag($0)
                        .accessibilityIdentifier("JournalDisplayModeOption.\($0.id)")
                }
            }
        } label: {
            Label(.journalDisplayMode, systemImage: "square.grid.2x2")
        }
        .accessibilityValue(displayMode.localizedTitle)
        .accessibilityIdentifier("JournalDisplayModeButton")
    }

    var pagePicker: some View {
        Menu {
            Picker(.journalRange, selection: $selectedPage) {
                ForEach(0 ..< pageCount, id: \.self) { page in
                    Text(JournalGridPagination.pageTitle(page: page, totalDays: totalDays))
                        .tag(page)
                }
            }
        } label: {
            Label(JournalGridPagination.pageTitle(page: clampedSelectedPage, totalDays: totalDays), systemImage: "calendar")
        }
    }

    var previousPageButton: some View {
        Button {
            selectedPage = Self.previousPage(from: clampedSelectedPage, totalDays: totalDays)
        } label: {
            Image(systemName: "chevron.left")
        }
        .disabled(clampedSelectedPage == 0)
        .accessibilityLabel(.journalRangePrevious)
    }

    var nextPageButton: some View {
        Button {
            selectedPage = Self.nextPage(from: clampedSelectedPage, totalDays: totalDays)
        } label: {
            Image(systemName: "chevron.right")
        }
        .disabled(clampedSelectedPage >= pageCount - 1)
        .accessibilityLabel(.journalRangeNext)
    }
}

extension JournalScreen {
    static func shouldShowPaginationControls(displayMode: DisplayMode, totalDays: Int) -> Bool {
        switch displayMode {
        case .list, .grid:
            JournalGridPagination.shouldShowPaginationControls(totalDays: totalDays)
        }
    }

    static func previousPage(from page: Int, totalDays: Int) -> Int {
        JournalGridPagination.previousPage(from: page, totalDays: totalDays)
    }

    static func nextPage(from page: Int, totalDays: Int) -> Int {
        JournalGridPagination.nextPage(from: page, totalDays: totalDays)
    }
}

#if DEBUG
#Preview("Без продления") {
    let statusManager = StatusManager.preview
    NavigationStack {
        JournalScreen(user: .init(from: .preview))
            .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
            .environment(statusManager)
    }
    .currentDay(statusManager.currentDayCalculator?.currentDay)
}

#Preview("С продлением календаря") {
    let statusManager = StatusManager.previewWithCalendarExtension
    NavigationStack {
        JournalScreen(user: .init(from: .preview))
            .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
            .environment(statusManager)
    }
    .currentDay(statusManager.currentDayCalculator?.currentDay)
}

#Preview("С продлением, день 130") {
    let statusManager = StatusManager.previewWithCalendarExtensionDay130
    NavigationStack {
        JournalScreen(user: .init(from: .preview))
            .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
            .environment(statusManager)
    }
    .currentDay(statusManager.currentDayCalculator?.currentDay)
}
#endif
