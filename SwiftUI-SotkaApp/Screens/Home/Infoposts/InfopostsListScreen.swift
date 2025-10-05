import OSLog
import SwiftData
import SwiftUI

/// Экран списка инфопостов с группировкой по секциям
struct InfopostsListScreen: View {
    private let logger = Logger(subsystem: "SotkaApp", category: "InfopostsListScreen")
    @Environment(InfopostsService.self) private var infopostsService
    @Environment(\.modelContext) private var modelContext
    @State private var infoposts: [Infopost] = []
    @State private var favoriteIds: Set<String> = []
    @State private var displayMode: InfopostsDisplayMode = .all

    /// Фильтрованные инфопосты в зависимости от режима отображения
    private var filteredInfoposts: [Infopost] {
        if displayMode.showsOnlyFavorites {
            return infoposts.filter { favoriteIds.contains($0.id) }
        }
        return infoposts
    }

    /// Секции, которые содержат хотя бы один инфопост для отображения
    private var sectionsWithContent: [InfopostSection] {
        InfopostSection.allCases.filter { section in
            !filteredInfoposts.filter { $0.section == section }.isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            displayModePicker
            List(sectionsWithContent, id: \.self) { section in
                Section(header: Text(section.localizedTitle)) {
                    ForEach(filteredInfoposts.filter { $0.section == section }) { infopost in
                        NavigationLink(destination: InfopostDetailScreen(infopost: infopost)) {
                            Text(infopost.title)
                        }
                    }
                }
            }
        }
        .navigationTitle("Infoposts")
        .onChange(of: favoriteIds) { _, newValue in
            if newValue.isEmpty {
                displayMode = .all
            }
        }
        .onAppear {
            do {
                if infoposts.isEmpty {
                    infoposts = try infopostsService.loadInfoposts()
                }
                favoriteIds = try Set(infopostsService.getFavoriteInfopostIds(modelContext: modelContext))
            } catch {
                logger.error("Ошибка загрузки: \(error.localizedDescription)")
            }
        }
    }
}

private extension InfopostsListScreen {
    @ViewBuilder
    var displayModePicker: some View {
        if !favoriteIds.isEmpty {
            Picker("Infoposts.Display Mode", selection: $displayMode) {
                ForEach(InfopostsDisplayMode.allCases) {
                    Text($0.title).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding([.top, .horizontal])
        }
    }
}
