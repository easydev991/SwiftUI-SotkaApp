import SwiftUI

private struct ScreenAnalyticsModifier: ViewModifier {
    @Environment(\.analyticsService) private var analytics
    let screen: AnalyticsEvent.AppScreen

    func body(content: Content) -> some View {
        content.onAppear {
            analytics.log(.screenView(screen: screen))
        }
    }
}

extension View {
    func trackScreen(_ screen: AnalyticsEvent.AppScreen) -> some View {
        modifier(ScreenAnalyticsModifier(screen: screen))
    }
}
