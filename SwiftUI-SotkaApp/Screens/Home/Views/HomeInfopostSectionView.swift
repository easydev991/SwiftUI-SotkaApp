import SWDesignSystem
import SwiftUI

/// Секция "Инфопост" на главном экране
///
/// Отображает изображение дня и название статьи с навигацией к инфопосту
struct HomeInfopostSectionView: View {
    @Environment(\.currentDay) private var currentDay
    let infopost: Infopost?

    var body: some View {
        if let infopost {
            HomeSectionView(title: String(localized: .infopost)) {
                NavigationLink {
                    InfopostDetailScreen(infopost: infopost)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        imageView
                        makeShortTitleWithChevronView(infopost.shortTitle)
                    }
                }
                .accessibilityIdentifier("TodayInfopostButton")
            }
        }
    }
}

private extension HomeInfopostSectionView {
    var imageView: some View {
        GeometryReader { geo in
            Image("\(currentDay)-1")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width)
        }
        .frame(height: 180)
        .clipped()
    }

    func makeShortTitleWithChevronView(_ text: String) -> some View {
        HStack {
            Text(text)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            ChevronView()
        }
        .padding([.bottom, .horizontal], 12)
    }
}

#if DEBUG
#Preview("День 2", traits: .sizeThatFitsLayout) {
    HomeInfopostSectionView(infopost: .preview)
        .padding()
        .currentDay(2)
}
#endif
