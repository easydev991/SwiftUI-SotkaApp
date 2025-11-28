import SWDesignSystem
import SwiftUI

struct ThemeIconScreen: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var iconViewModel = ViewModel()

    var body: some View {
        List {
            Section {
                themePicker
            }
            Section(.themeIconScreenIconSection) {
                iconsGrid
                    .buttonStyle(.plain)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(.themeIconScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var themePicker: some View {
        @Bindable var settings = appSettings
        Picker(.themeIconScreenThemePicker, selection: $settings.appTheme) {
            ForEach(AppTheme.allCases) {
                Text($0.localizedTitle).tag($0)
            }
        }
        .accessibilityIdentifier("themePicker")
    }

    private var iconsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 65), alignment: .leading)],
            spacing: 32
        ) {
            ForEach(IconVariant.allCases, id: \.self) { icon in
                Button {
                    Task { await iconViewModel.setIcon(icon) }
                } label: {
                    makeView(for: icon)
                }
                .accessibilityLabel(icon.accessibilityLabel)
            }
        }
        .accessibilityIdentifier("appIconsGrid")
    }

    private func makeView(for icon: IconVariant) -> some View {
        icon
            .listImage
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.secondary.opacity(0.5), lineWidth: 1)
            }
            .drawingGroup()
            .overlay(alignment: .topTrailing) {
                if icon == iconViewModel.currentAppIcon {
                    Image(systemName: "checkmark")
                        .symbolVariant(.circle.fill)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.swAccent)
                        .offset(x: 6, y: -6)
                        .transition(.opacity.combined(with: .scale))
                        .accessibilityHidden(true)
                }
            }
            .animation(.default, value: icon == iconViewModel.currentAppIcon)
    }
}

#Preview {
    NavigationStack {
        ThemeIconScreen()
            .environment(AppSettings())
    }
}
