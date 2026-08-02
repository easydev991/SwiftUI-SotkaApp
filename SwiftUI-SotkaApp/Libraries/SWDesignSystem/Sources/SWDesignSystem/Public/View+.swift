import SwiftUI

public extension View {
    /// Добавляет фон для карточки
    ///
    /// `padding` - отступы вокруг контента, по умолчанию 12
    func insideCardBackground(padding: CGFloat = 12) -> some View {
        modifier(CardBackgroundModifier(padding: padding))
    }

    /// Добавляет в оверлей индикатор загрузки
    func loadingOverlay(if isLoading: Bool) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading))
    }

    /// Добавляет тень в светлой теме
    func withShadow() -> some View {
        modifier(ShadowIfNeededModifier())
    }
}
