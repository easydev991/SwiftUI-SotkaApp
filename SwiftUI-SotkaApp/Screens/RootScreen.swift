//
//  RootScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 04.05.2025.
//

import SwiftUI
import SwiftData

struct RootScreen: View {
    @State private var tab = Tab.demo

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
        case demo
        case more

        private var localizedTitle: LocalizedStringKey {
            self == .demo ? "Demo" : "More"
        }

        private var systemImageName: String {
            self == .demo
            ? "list.bullet"
            : "gear"
        }

        private var accessibilityId: String {
            switch self {
            case .demo: "demoTabButton"
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
            case .demo: DemoSwiftDataScreen()
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
