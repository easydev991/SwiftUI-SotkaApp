import SwiftUI

struct ProgressStatsInfoView: View {
    private let items: [Model]

    init(
        fullProgressPercent: Int,
        infoPostsPercent: Int,
        activityPercent: Int
    ) {
        self.items = [
            .init(value: fullProgressPercent, option: .fullProgress),
            .init(value: infoPostsPercent, option: .infoposts),
            .init(value: activityPercent, option: .activities)
        ]
    }

    var body: some View {
        NavigationStack {
            List {
                Section(.progressStatsMetrics) {
                    ForEach(items) { item in
                        HStack(spacing: 4) {
                            Text(item.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(item.subtitle).bold()
                        }
                    }
                }
                legendSection
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(.progressStatsTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension ProgressStatsInfoView {
    struct Model: Identifiable {
        let id = UUID().uuidString
        let title: String
        let subtitle: String
        let hasDivider: Bool

        init(value: Int, option: Option) {
            self.title = option.localizedTitle
            self.subtitle = "\(value)%"
            self.hasDivider = option.hasDivider
        }

        enum Option {
            case fullProgress
            case infoposts
            case activities

            var localizedTitle: String {
                switch self {
                case .fullProgress: String(localized: .progressFullProgressTitle)
                case .infoposts: String(localized: .progressInfoPostsTitle)
                case .activities: String(localized: .progressActivityTitle)
                }
            }

            var hasDivider: Bool {
                self != .activities
            }
        }
    }
}

private extension ProgressStatsInfoView {
    var legendSection: some View {
        Section(.progressStatsLegend) {
            ForEach(DayProgressStatus.allCases) { status in
                HStack(spacing: 12) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 16, height: 16)
                    Text(status.localizedTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ProgressStatsInfoView(
        fullProgressPercent: 75,
        infoPostsPercent: 80,
        activityPercent: 70
    )
}
#endif
