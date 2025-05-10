//
//  RootScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 04.05.2025.
//

import SwiftUI
import SwiftData

struct RootScreen: View {
    @State private var tab = Tab.home

    var body: some View {
        TabView(selection: $tab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tab.screen
                    .tabItem { tab.tabItemLabel }
                    .tag(tab)
            }
        }
    }
}

extension RootScreen {
    private enum Tab: CaseIterable {
        case home
        case profile
        case more

        private var localizedTitle: LocalizedStringKey {
            switch self {
            case .home: "Home"
            case .profile: "Profile"
            case .more: "More"
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
            case .home: DemoSwiftDataScreen()
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
