import SWDesignSystem
import SwiftData
import SwiftUI

struct JournalScreen: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.modelContext) private var modelContext
    @AppStorage(DisplayMode.appStorageKey) private var displayMode = DisplayMode.grid
    let user: User

    var body: some View {
        VStack(spacing: 12) {
            displayModePicker
            Text(.journal)
        }
        .navigationTitle(.journal)
    }
}

extension JournalScreen {
    enum DisplayMode: Int, Equatable, CaseIterable, Identifiable {
        var id: Int { rawValue }
        case list
        case grid

        var title: String {
            switch self {
            case .list: String(localized: .journalDisplayModeList)
            case .grid: String(localized: .journalDisplayModeGrid)
            }
        }

        static let appStorageKey = "JournalDisplayMode"
    }
}

private extension JournalScreen {
    var displayModePicker: some View {
        Picker(.journalDisplayMode, selection: $displayMode) {
            ForEach(DisplayMode.allCases) {
                Text($0.title).tag($0)
            }
        }
        .pickerStyle(.segmented)
        .padding([.top, .horizontal])
    }
}

#if DEBUG
#Preview {
    JournalScreen(user: .init(from: .preview))
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
}
#endif
