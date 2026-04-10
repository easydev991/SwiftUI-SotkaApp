import SwiftUI

private struct AnalyticsEventModifier: ViewModifier {
    @Environment(\.analyticsService) private var analytics
    let event: AnalyticsEvent

    func body(content: Content) -> some View {
        content.onAppear {
            analytics.log(event)
        }
    }
}

extension View {
    func trackEvent(_ event: AnalyticsEvent) -> some View {
        modifier(AnalyticsEventModifier(event: event))
    }

    func trackScreen(_ screen: AnalyticsEvent.AppScreen) -> some View {
        trackEvent(.screenView(screen: screen))
    }
}
