import SWDesignSystem
import SwiftData
import SwiftUI

/// Экран списка инфопостов с группировкой по секциям
struct InfopostsListScreen: View {
    @Environment(InfopostsService.self) private var infopostsService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 12) {
            displayModePicker
            List(infopostsService.sectionsForDisplay) { sectionDisplay in
                Section(header: makeHeader(for: sectionDisplay)) {
                    if !sectionDisplay.isCollapsed {
                        ForEach(sectionDisplay.infoposts) { infopost in
                            makeView(for: infopost)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(.infoposts)
        .task {
            try? await infopostsService.syncReadPosts(modelContext: modelContext)
        }
        .onAppear {
            try? infopostsService.loadFavoriteIds(modelContext: modelContext)
        }
    }
}

private extension InfopostsListScreen {
    @ViewBuilder
    var displayModePicker: some View {
        if infopostsService.showDisplayModePicker {
            @Bindable var service = infopostsService
            Picker(.infopostsDisplayMode, selection: $service.displayMode) {
                ForEach(InfopostsDisplayMode.allCases) {
                    Text($0.title).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding([.top, .horizontal])
        }
    }

    func makeHeader(for sectionDisplay: InfopostSectionDisplay) -> some View {
        Button {
            withAnimation {
                infopostsService.didTapSection(sectionDisplay.section)
            }
        } label: {
            HStack(spacing: 12) {
                Text(sectionDisplay.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ChevronView()
                    .rotationEffect(.degrees(sectionDisplay.isCollapsed ? 0 : 90))
                    .animation(.default, value: sectionDisplay.isCollapsed)
            }
        }
        .buttonStyle(.plain)
    }

    func makeView(for infopost: Infopost) -> some View {
        NavigationLink(destination: InfopostDetailScreen(infopost: infopost)) {
            HStack(spacing: 12) {
                makeIndicator(for: infopost)
                Text(infopost.title)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            makeReadAction(for: infopost)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            makeFavoriteAction(for: infopost)
        }
    }

    @ViewBuilder
    func makeIndicator(for infopost: Infopost) -> some View {
        if let isRead = try? infopostsService.isPostRead(infopost, modelContext: modelContext),
           !isRead {
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
        }
    }

    @ViewBuilder
    func makeReadAction(for infopost: Infopost) -> some View {
        if let isRead = try? infopostsService.isPostRead(infopost, modelContext: modelContext),
           !isRead {
            Button {
                Task {
                    try? await infopostsService.markPostAsRead(day: infopost.dayNumber, modelContext: modelContext)
                }
            } label: {
                Image(systemName: "checkmark.circle.fill")
            }
            .tint(.blue)
        }
    }

    @ViewBuilder
    func makeFavoriteAction(for infopost: Infopost) -> some View {
        if infopost.isFavoriteAvailable {
            let isFavorite = infopostsService.isFavorite(infopost, modelContext: modelContext)
            Button {
                withAnimation {
                    try? infopostsService.changeFavorite(id: infopost.id, modelContext: modelContext)
                }
            } label: {
                Image(systemName: isFavorite ? "star.slash.fill" : "star.fill")
            }
        }
    }
}
