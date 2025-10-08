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
            Picker("Infoposts.DisplayMode", selection: $service.displayMode) {
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
}
