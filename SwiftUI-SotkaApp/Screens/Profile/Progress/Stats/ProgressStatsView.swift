import SwiftData
import SwiftUI
import TipKit

/// Подсказка для статистики прогресса
struct ProgressStatsTip: Tip {
    static let reachedTenthDay = Event(id: "reachedTenthDay")

    var id: String { "ProgressTip.StatsView" }

    var title: Text {
        Text(.progressTipStatsViewTitle)
    }

    var message: Text? {
        Text(.progressTipStatsViewMessage)
    }

    var rules: [Rule] {
        #Rule(Self.reachedTenthDay) { $0.donations.count > 0 }
    }

    var options: [any TipOption] {
        [MaxDisplayCount(2)]
    }
}

/// Основная вьюха для отображения статистики прогресса
struct ProgressStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.currentDay) private var currentDay
    @State private var viewModel = ProgressStatsViewModel()
    @State private var showInfoSheet = false
    private let tip = ProgressStatsTip()

    var body: some View {
        Button {
            showInfoSheet.toggle()
            tip.invalidate(reason: .actionPerformed)
        } label: {
            ProgressBarView(days: viewModel.dayStatuses)
        }
        .popoverTip(tip)
        .onAppear {
            viewModel.updateStats(
                modelContext: modelContext,
                currentDay: currentDay
            )
        }
        .task(id: currentDay) {
            if currentDay >= 10 {
                await ProgressStatsTip.reachedTenthDay.donate()
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ProgressStatsInfoView(
                fullProgressPercent: viewModel.fullProgressPercent,
                infoPostsPercent: viewModel.infoPostsPercent,
                activityPercent: viewModel.activityPercent
            )
            .presentationDetents([.medium, .large])
        }
    }
}

#if DEBUG
#Preview("День 25") {
    ProgressStatsView()
        .currentDay(25)
        .modelContainer(PreviewModelContainer.make(with: .preview))
}
#endif
