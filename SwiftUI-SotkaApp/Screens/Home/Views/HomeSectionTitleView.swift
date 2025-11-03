import SWDesignSystem
import SwiftUI

struct HomeSectionTitleView<MenuContent: View>: View {
    let title: String
    let showMenu: Bool
    @ViewBuilder let menuContent: () -> MenuContent

    init(title: String) where MenuContent == EmptyView {
        self.title = title
        self.showMenu = false
        self.menuContent = { EmptyView() }
    }

    init(title: String, showMenu: Bool, @ViewBuilder menuContent: @escaping () -> MenuContent) {
        self.title = title
        self.showMenu = showMenu
        self.menuContent = menuContent
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.swMainText)
            Spacer()
            if showMenu {
                Menu(content: menuContent) {
                    Image(systemName: "ellipsis")
                        .symbolVariant(.circle)
                }
            }
        }
        .padding([.top, .horizontal], 12)
    }
}

#Preview {
    HomeSectionTitleView(title: "Title")
}
