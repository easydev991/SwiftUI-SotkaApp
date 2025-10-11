import SWDesignSystem
import SwiftUI

/// Секция "Инфопост" на главном экране
///
/// Отображает изображение дня и название статьи с навигацией к инфопосту
struct HomeInfopostSectionView: View {
    let currentDay: Int
    let infopost: Infopost

    var body: some View {
        HomeSectionView(title: "Infopost") {
            navigationLinkView
        }
    }
}

private extension HomeInfopostSectionView {
    var navigationLinkView: some View {
        NavigationLink {
            InfopostDetailScreen(infopost: infopost)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                imageView
                shortTitleWithChevronView
            }
        }
    }

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

    var shortTitleWithChevronView: some View {
        HStack {
            Text(infopost.shortTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            ChevronView()
        }
        .padding([.bottom, .horizontal], 12)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HomeInfopostSectionView(
        currentDay: 2,
        infopost: .preview
    )
    .padding()
}
