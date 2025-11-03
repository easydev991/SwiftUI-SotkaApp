import SWDesignSystem
import SwiftUI

struct HomeFillProgressSectionView: View {
    var body: some View {
        HomeSectionView(title: String(localized: .homeProgress)) {
            NavigationLink(value: HomeScreen.NavigationDestination.userProgress) {
                HStack {
                    Text(.homeFillResults)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ChevronView()
                }
                .padding([.horizontal, .bottom], 12)
            }
        }
    }
}

#if DEBUG
#Preview {
    HomeFillProgressSectionView().padding()
}
#endif
