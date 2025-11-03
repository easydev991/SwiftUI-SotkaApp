import SWDesignSystem
import SwiftUI

struct HomeSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionTitleView(title: title)
            content
        }
        .foregroundStyle(Color.swMainText)
        .insideCardBackground(padding: 0)
    }
}

#Preview {
    HomeSectionView(title: "Activity") {
        Text("Hello, World!")
            .frame(maxWidth: .infinity)
            .padding([.horizontal, .bottom])
    }
    .padding()
}
