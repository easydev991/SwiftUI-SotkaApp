import SWDesignSystem
import SwiftUI

struct JournalScreen: View {
    @AppStorage(SortOrder.appStorageKey) private var sortOrder = SortOrder.forward
    @AppStorage(DisplayMode.appStorageKey) private var displayMode = DisplayMode.grid
    let user: User

    var body: some View {
        VStack(spacing: 12) {
            switch displayMode {
            case .list:
                JournalListView(
                    activitiesByDay: user.activitiesByDay,
                    sortOrder: sortOrder
                )
            case .grid:
                JournalGridView(activitiesByDay: user.activitiesByDay)
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
            ToolbarItem(placement: .topBarTrailing) {
                displayModeButton
            }
        }
        .animation(.default, value: displayMode)
        .background(Color.swBackground)
        .navigationTitle(.journal)
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension JournalScreen {
    enum DisplayMode: Int, Equatable, CaseIterable, Identifiable {
        var id: Int { rawValue }
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
                }
            }
        } label: {
            Label(.journalDisplayMode, systemImage: "square.grid.2x2")
        }
        .accessibilityValue(displayMode.localizedTitle)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        JournalScreen(user: .init(from: .preview))
            .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
    }
}
#endif
