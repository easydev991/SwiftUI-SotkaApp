import SwiftData
import SwiftUI
import SWUtils

struct RootScreen: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var tab = Tab.home

    var body: some View {
        @Bindable var settings = appSettings
        TabView(selection: $tab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tab.screen
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
    }
}

extension RootScreen {
    private enum Tab: CaseIterable {
        case home
        case profile
        case more

        private var localizedTitle: String {
            switch self {
            case .home: String(localized: .home)
            case .profile: String(localized: .profile)
            case .more: String(localized: .more)
            }
        }

        private var systemImageName: String {
            switch self {
            case .home: "house"
            case .profile: "person"
            case .more: "gear"
            }
        }

        private var accessibilityId: String {
            switch self {
            case .home: "demoTabButton"
            case .profile: "profileTabButton"
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
        var screen: some View {
            switch self {
            case .home: HomeScreen()
            case .profile: ProfileScreen()
            case .more: MoreScreen()
            }
        }
    }
}

#if DEBUG
#Preview {
    RootScreen()
        .environment(AppSettings())
}
#endif
