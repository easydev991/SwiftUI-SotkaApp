import SwiftData
import SwiftUI
import SWUtils

struct RootScreen: View {
    @Environment(AppSettings.self) private var appSettings
    @Query private var users: [User]
    @State private var tab = Tab.home

    private var user: User? {
        users.first
    }

    var body: some View {
        @Bindable var settings = appSettings
        TabView(selection: $tab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tab.tabContent(user: user)
                    .tabItem { tab.tabItemLabel }
                    .tag(tab)
            }
        }
        .alert(
            isPresented: $settings.showNotificationError,
            error: appSettings.notificationError
        ) {
            Button(.cancel, role: .cancel) {}
            Button(.goToSettings) {
                let settingsUrl = URL(string: UIApplication.openSettingsURLString)
                URLOpener.open(settingsUrl)
            }
        }
        .trackScreen(.root)
    }
}

extension RootScreen {
    private enum Tab: CaseIterable {
        case home
        case journal
        case progress
        case more

        private var localizedTitle: String {
            switch self {
            case .home: String(localized: .home)
            case .journal: String(localized: .journal)
            case .progress: String(localized: .progress)
            case .more: String(localized: .more)
            }
        }

        private var systemImageName: String {
            switch self {
            case .home: "house"
            case .journal: "book.closed"
            case .progress: "chart.line.uptrend.xyaxis"
            case .more: "gear"
            }
        }

        private var accessibilityId: String {
            switch self {
            case .home: "demoTabButton"
            case .journal: "journalTabButton"
            case .progress: "progressTabButton"
            case .more: "moreTabButton"
            }
        }

        var tabItemLabel: some View {
            Label(
                localizedTitle,
                systemImage: systemImageName
            )
            .accessibilityIdentifier(accessibilityId)
        }

        @MainActor @ViewBuilder
        fileprivate func tabContent(user: User?) -> some View {
            switch self {
            case .home:
                HomeScreen()
            case .journal:
                if let user {
                    NavigationStack {
                        JournalScreen(user: user)
                    }
                } else {
                    ProgressView()
                }
            case .progress:
                if let user {
                    NavigationStack {
                        ProgressScreen(user: user)
                    }
                } else {
                    ProgressView()
                }
            case .more:
                MoreScreen()
            }
        }
    }
}

#if DEBUG
#Preview {
    RootScreen()
        .environment(AppSettings())
        .environment(StatusManager.preview)
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
        .environment(AuthHelperImp())
        .modelContainer(PreviewModelContainer.make(with: .preview))
}
#endif
