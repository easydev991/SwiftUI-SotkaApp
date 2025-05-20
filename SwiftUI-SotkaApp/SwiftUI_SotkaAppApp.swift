//
//  SwiftUI_SotkaAppApp.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 04.05.2025.
//

import SwiftUI
import SwiftData
import SWUtils

@main
struct SwiftUI_SotkaAppApp: App {
    @State private var appSettings = AppSettings()
    @State private var authHelper = AuthHelperImp()
    @State private var networkStatus = NetworkStatus()

    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([User.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Не смогли создать ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authHelper.isAuthorized {
                    RootScreen()
                } else {
                    LoginScreen()
                }
            }
            .animation(.default, value: authHelper.isAuthorized)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .environment(appSettings)
            .environment(authHelper)
            .environment(\.isNetworkConnected, networkStatus.isConnected)
            .preferredColorScheme(appSettings.appTheme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: authHelper.isAuthorized) { _, isAuthorized in
            appSettings.setWorkoutNotificationsEnabled(isAuthorized)
            if !isAuthorized {
                appSettings.didLogout()
            }
        }
    }
}
