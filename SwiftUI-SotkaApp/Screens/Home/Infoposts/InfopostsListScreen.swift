import OSLog
import SWDesignSystem
import SwiftData
import SwiftUI

/// Экран списка инфопостов с группировкой по секциям
struct InfopostsListScreen: View {
    private let logger = Logger(subsystem: "SotkaApp", category: "InfopostsListScreen")
    @Environment(InfopostsService.self) private var infopostsService
    @Environment(StatusManager.self) private var statusManager
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var availableInfoposts: [Infopost] = []
    @State private var favoriteIds: Set<String> = []
    @State private var displayMode: InfopostsDisplayMode = .all
    @State private var collapsedSections: Set<InfopostSection> = []
    private var userGender: Gender? {
        guard let genderCode = users.first?.genderCode else { return nil }
        return Gender(genderCode)
    }

    /// Фильтрованные инфопосты с учетом режима отображения и пола пользователя
    /// (доступность уже учтена при загрузке availableInfoposts)
    private var filteredInfoposts: [Infopost] {
        availableInfoposts.filter { infopost in
            // Проверяем соответствие полу пользователя
            let genderMatches = userGender == nil || infopost.gender == nil || infopost.gender == userGender

            // Проверяем режим отображения (все/избранные)
            let favoriteMatches = !displayMode.showsOnlyFavorites || favoriteIds.contains(infopost.id)

            return genderMatches && favoriteMatches
        }
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
                Section(header: makeHeader(for: section)) {
                    if !collapsedSections.contains(section) {
                        ForEach(filteredInfoposts.filter { $0.section == section }) { infopost in
                            NavigationLink(destination: InfopostDetailScreen(infopost: infopost)) {
                                Text(infopost.title)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Infoposts")
        .onChange(of: favoriteIds) { _, newValue in
            if newValue.isEmpty {
                displayMode = .all
            }
        }
        .task {
            do {
                try await infopostsService.syncReadPosts(modelContext: modelContext)
            } catch {
                logger.error("Ошибка синхронизации прочитанных постов: \(error.localizedDescription)")
            }
        }
        .onAppear {
            loadAvailableInfoposts()
            loadFavoriteIds()
        }
        .onChange(of: statusManager.currentDayCalculator) { _, _ in
            // Перезагружаем доступные инфопосты при изменении дня программы
            loadAvailableInfoposts()
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

    func makeHeader(for section: InfopostSection) -> some View {
        Button {
            withAnimation {
                if collapsedSections.contains(section) {
                    collapsedSections.remove(section)
                } else {
                    collapsedSections.insert(section)
                }
            }
        } label: {
            HStack(spacing: 12) {
                let isCollapsed = collapsedSections.contains(section)
                Text(section.localizedTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ChevronView()
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                    .animation(.default, value: isCollapsed)
            }
        }
        .buttonStyle(.plain)
    }

    /// Загружает только доступные инфопосты в зависимости от текущего дня
    func loadAvailableInfoposts() {
        guard availableInfoposts.isEmpty else { return }
        do {
            availableInfoposts = try infopostsService.getAvailableInfoposts(
                currentDay: statusManager.currentDayCalculator?.currentDay,
                maxReadInfoPostDay: statusManager.maxReadInfoPostDay
            )
        } catch {
            logger.error("Ошибка загрузки доступных инфопостов: \(error.localizedDescription)")
            availableInfoposts = []
        }
    }

    /// Загружает список избранных инфопостов
    func loadFavoriteIds() {
        do {
            favoriteIds = try Set(infopostsService.getFavoriteInfopostIds(modelContext: modelContext))
        } catch {
            logger.error("Ошибка загрузки избранных инфопостов: \(error.localizedDescription)")
            favoriteIds = []
        }
    }
}
