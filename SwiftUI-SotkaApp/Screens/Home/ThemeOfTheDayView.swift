import SWDesignSystem
import SwiftUI

/// Секция "Тема дня" на главном экране
///
/// Отображает изображение дня и название статьи с навигацией к инфопосту
struct ThemeOfTheDayView: View {
    let currentDay: Int
    let infopost: Infopost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            imageView
            navigationLinkView
        }
        .foregroundStyle(Color.swMainText)
        .insideCardBackground(padding: 0)
    }
}

private extension ThemeOfTheDayView {
    var headerView: some View {
        Text("Home.Theme")
            .font(.title3.bold())
            .padding([.top, .horizontal], 12)
    }

    var imageView: some View {
        GeometryReader { geo in
            Image("\(currentDay)-1")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width)
                .clipped()
        }
        .frame(height: 220)
    }

    var navigationLinkView: some View {
        NavigationLink {
            InfopostDetailScreen(infopost: infopost)
        } label: {
            HStack {
                Text(infopost.shortTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ChevronView()
            }
            .padding([.bottom, .horizontal], 12)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ThemeOfTheDayView(
        currentDay: 2,
        infopost: .preview
    )
    .padding()
}
