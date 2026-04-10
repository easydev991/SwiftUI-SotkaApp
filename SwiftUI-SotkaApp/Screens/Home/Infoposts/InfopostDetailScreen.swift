import OSLog
import SwiftData
import SwiftUI
import WebKit

/// Детальный экран инфопоста с `WKWebView` для отображения `HTML` контента
struct InfopostDetailScreen: View {
    private let logger = Logger(subsystem: "SotkaApp", category: "InfopostDetailScreen")
    @AppStorage(FontSize.appStorageKey) private var fontSize = FontSize.medium
    @Environment(\.analyticsService) private var analytics
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @Environment(InfopostsService.self) private var infopostsService
    @Environment(\.modelContext) private var modelContext
    @State private var isFavorite = false
    @State private var showError = false
    @State private var currentError: HTMLContentView.InfopostError?
    let infopost: Infopost

    var body: some View {
        HTMLContentView(
            infopost: infopost,
            fontSize: fontSize,
            showError: $showError,
            currentError: $currentError,
            onReachedEnd: didReadPost
        )
        .alert(isPresented: $showError, error: currentError) {
            Button(.close, role: .cancel) {
                dismiss()
            }
            Button(.report) {
                appSettings.sendFeedback(message: currentError?.localizedDescription)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .trackScreen(.infopostDetail)
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
            isFavorite = infopostsService.isFavorite(infopost, modelContext: modelContext)
        }
        .onChange(of: fontSize) { _, newValue in
            analytics.log(
                .userAction(
                    action: .selectInfopostFontSize(
                        size: newValue.rawValue,
                        entityId: infopost.id
                    )
                )
            )
        }
    }
}

private extension InfopostDetailScreen {
    var fontSizeButton: some View {
        Menu {
            Picker(.fontSize, selection: $fontSize) {
                ForEach(FontSize.allCases) {
                    Text($0.localizedTitle).tag($0)
                }
            }
        } label: {
            Label(.fontSize, systemImage: "textformat.size")
        }
        .accessibilityValue(fontSize.localizedTitle)
    }

    var favoriteButton: some View {
        Button {
            let nextFavoriteState = !isFavorite
            analytics.log(
                .userAction(
                    action: .infopostFavoriteChanged(
                        isFavorite: nextFavoriteState,
                        infopostNumber: infopost.dayNumber ?? 0
                    )
                )
            )
            do {
                try infopostsService.changeFavorite(id: infopost.id, modelContext: modelContext)
                isFavorite.toggle()
                logger.info("Статус избранного изменен для инфопоста: \(infopost.id)")
            } catch {
                analytics.log(.appError(kind: .infopostFavoriteFailed, error: error))
                logger.error("Ошибка изменения статуса избранного: \(error.localizedDescription)")
            }
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
        }
    }

    func didReadPost() {
        analytics.log(.userAction(action: .markInfopostRead))
        Task {
            try? await infopostsService.markPostAsRead(day: infopost.dayNumber, modelContext: modelContext)
        }
    }
}
