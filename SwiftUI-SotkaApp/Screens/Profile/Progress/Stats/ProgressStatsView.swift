import SwiftData
import SwiftUI

/// Основная вьюха для отображения статистики прогресса
struct ProgressStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.currentDay) private var currentDay
    @State private var viewModel = ProgressStatsViewModel()
    @State private var showInfoSheet = false

    var body: some View {
        Button {
            showInfoSheet.toggle()
        } label: {
            ProgressBarView(days: viewModel.dayStatuses)
        }
        .onAppear {
            viewModel.updateStats(
                modelContext: modelContext,
                currentDay: currentDay
            )
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
