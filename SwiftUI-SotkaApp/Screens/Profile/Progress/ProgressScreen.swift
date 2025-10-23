import OSLog
import SwiftData
import SwiftUI

struct ProgressScreen: View {
    private let logger = Logger(subsystem: "SwiftUI-SotkaApp", category: "ProgressScreen")
    @Query(filter: #Predicate<UserProgress> { progress in
        progress.shouldDelete == false
    }) var items: [UserProgress]
    @Environment(StatusManager.self) private var statusManager
    @State private var navigationDestination: ProgressDestination?
    let user: User

    var body: some View {
        ScrollView {
            gridView.padding()
        }
        .navigationTitle(.progress)
        .navigationDestination(item: $navigationDestination) { destination in
            switch destination {
            case let .editProgress(progress):
                EditProgressScreen(progress: progress, mode: .metrics)
            case let .editPhotos(progress):
                EditProgressScreen(progress: progress, mode: .photos)
            }
        }
        .onAppear {
            let logItems = items.map { "\($0.id): shouldDelete=\($0.shouldDelete)" }.joined(separator: ", ")
            logger.info("ProgressScreen появился, загружено \(items.count) элементов: [\(logItems)]")
        }
        .onChange(of: items) { _, newItems in
            let logItems = newItems.map { "\($0.id): shouldDelete=\($0.shouldDelete)" }.joined(separator: ", ")
            logger.info("ProgressScreen: изменились элементы, теперь \(newItems.count) элементов: [\(logItems)]")
        }
    }
}

private extension ProgressScreen {
    var gridView: some View {
        let currentDay = statusManager.currentDayCalculator?.currentDay ?? 1
        return ProgressGridView(
            user: user,
            progressItems: items,
            currentDay: currentDay,
            onProgressTap: { progress in
                navigationDestination = .editProgress(progress)
            },
            onPhotoTap: { progress, _ in
                navigationDestination = .editPhotos(progress)
            }
        )
    }

    /// Возвращает модель прогресса для указанной секции или заглушку
    func makeModel(for section: UserProgress.Section) -> UserProgress {
        user.progressResults.first { $0.id == section.rawValue } ?? .init(id: section.rawValue)
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
