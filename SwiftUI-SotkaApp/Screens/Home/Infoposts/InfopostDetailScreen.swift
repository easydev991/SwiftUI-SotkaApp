import OSLog
import SwiftData
import SwiftUI
import WebKit

/// Детальный экран инфопоста с `WKWebView` для отображения `HTML` контента
struct InfopostDetailScreen: View {
    private let logger = Logger(subsystem: "SotkaApp", category: "InfopostDetailScreen")
    @AppStorage(FontSize.appStorageKey) private var fontSize = FontSize.medium
    @Environment(InfopostsService.self) private var infopostsService
    @Environment(YouTubeVideoService.self) private var youtubeService
    @Environment(\.modelContext) private var modelContext
    @State private var isFavorite = false
    let infopost: Infopost

    var body: some View {
        HTMLContentView(
            filename: infopost.filenameWithLanguage,
            fontSize: fontSize,
            infopost: infopost,
            youtubeService: youtubeService,
            onReachedEnd: didReadPost
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                fontSizeButton
            }
            if infopost.isFavoriteAvailable {
                ToolbarItem(placement: .topBarTrailing) {
                    favoriteButton
                }
            }
        }
        .onAppear {
            do {
                isFavorite = try infopostsService.isInfopostFavorite(infopost, modelContext: modelContext)
                logger.debug("Загружен статус избранного для инфопоста: \(infopost.id) - \(isFavorite)")
            } catch {
                logger.error("Ошибка загрузки статуса избранного: \(error.localizedDescription)")
            }
        }
    }
}

private extension InfopostDetailScreen {
    var fontSizeButton: some View {
        Menu {
            ForEach(FontSize.allCases) { size in
                Button {
                    fontSize = size
                } label: {
                    Text(size.title)
                    if size == fontSize {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Label("Font Size", systemImage: "textformat.size")
        }
    }

    var favoriteButton: some View {
        Button {
            do {
                try infopostsService.changeFavorite(id: infopost.id, modelContext: modelContext)
                isFavorite.toggle()
                logger.info("Статус избранного изменен для инфопоста: \(infopost.id)")
            } catch {
                logger.error("Ошибка изменения статуса избранного: \(error.localizedDescription)")
            }
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
        }
    }

    func didReadPost() {
        Task {
            do {
                try await infopostsService.markPostAsRead(day: infopost.dayNumber, modelContext: modelContext)
                logger.info("📜 Инфопост помечен как прочитанный после достижения конца контента: \(infopost.id)")
            } catch {
                logger.error("Ошибка маркировки поста как прочитанного: \(error.localizedDescription)")
            }
        }
    }
}
