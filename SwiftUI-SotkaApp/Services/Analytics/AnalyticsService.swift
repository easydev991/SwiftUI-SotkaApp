import Foundation

struct AnalyticsService {
    private let providers: [any AnalyticsProvider]

    init(providers: [any AnalyticsProvider]) {
        self.providers = providers
    }

    func log(_ event: AnalyticsEvent) {
        providers.forEach { $0.log(event: event) }
    }
}
