import SwiftData
import SwiftUI

struct ProgressScreen: View {
    @Environment(\.analyticsService) private var analytics
    @Environment(StatusManager.self) private var statusManager
    @State private var navigationDestination: ProgressDestination?
    let user: User

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProgressStatsView()
                Divider()
                gridView
            }
            .padding()
        }
        .navigationTitle(.progress)
        .trackScreen(.progress)
        .navigationDestination(item: $navigationDestination) { destination in
            switch destination {
            case let .editProgress(progress):
                EditProgressScreen(
                    progress: progress,
                    mode: .metrics,
                    analytics: analytics
                )
            case let .editPhotos(progress):
                EditProgressScreen(
                    progress: progress,
                    mode: .photos,
                    analytics: analytics
                )
            }
        }
    }
}

private extension ProgressScreen {
    var gridView: some View {
        ProgressGridView(
            user: user,
            onProgressTap: { progress in
                analytics.log(.userAction(action: .editProgress(dayNumber: "\(progress.id)")))
                navigationDestination = .editProgress(progress)
            },
            onPhotoTap: { progress in
                analytics.log(.userAction(action: .editProgress(dayNumber: "\(progress.id)")))
                navigationDestination = .editPhotos(progress)
            }
        )
    }
}

#if DEBUG
#Preview("Без прогресса") {
    ProgressScreen(user: .preview)
        .environment(StatusManager.preview)
}

#Preview("День 1") {
    ProgressScreen(user: .previewWithDay1Progress)
        .environment(StatusManager.preview)
}

#Preview("День 49") {
    ProgressScreen(user: .previewWithDay49Progress)
        .environment(StatusManager.preview)
}

#Preview("День 100") {
    ProgressScreen(user: .previewWithDay100Progress)
        .environment(StatusManager.preview)
}

#Preview("Дни 1 + 49") {
    ProgressScreen(user: .previewWithDay1And49Progress)
        .environment(StatusManager.preview)
}

#Preview("Дни 49 + 100") {
    ProgressScreen(user: .previewWithDay49And100Progress)
        .environment(StatusManager.preview)
}

#Preview("Дни 1 + 100") {
    ProgressScreen(user: .previewWithDay1And100Progress)
        .environment(StatusManager.preview)
}

#Preview("Все дни") {
    ProgressScreen(user: .previewWithAllProgress)
        .environment(StatusManager.preview)
}
#endif
