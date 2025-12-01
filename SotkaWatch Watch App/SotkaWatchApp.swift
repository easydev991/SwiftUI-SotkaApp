import SwiftUI

@main
struct SotkaWatchApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(isAuthorized: true)
        }
    }
}
