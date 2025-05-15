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
    @State private var networkStatus = NetworkStatus()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Не смогли создать ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootScreen()
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .environment(appSettings)
                .environment(\.isNetworkConnected, networkStatus.isConnected)
                .preferredColorScheme(appSettings.appTheme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
