import OSLog
import SwiftData
import SwiftUI
import WebKit

/// Детальный экран инфопоста с `WKWebView` для отображения `HTML` контента
struct InfopostDetailScreen: View {
    private let logger = Logger(subsystem: "SotkaApp", category: "InfopostDetailScreen")
    @AppStorage(FontSize.appStorageKey) private var fontSize = FontSize.medium
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
            Button("Close", role: .cancel) {
                dismiss()
            }
            Button(.report) {
                appSettings.sendFeedback(message: currentError?.localizedDescription)
            }
        }
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
            isFavorite = infopostsService.isFavorite(infopost, modelContext: modelContext)
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
            Label(.fontSize, systemImage: "textformat.size")
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
            try? await infopostsService.markPostAsRead(day: infopost.dayNumber, modelContext: modelContext)
        }
    }
}
