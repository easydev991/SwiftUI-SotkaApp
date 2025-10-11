import SWDesignSystem
import SwiftUI

struct HomeSectionView<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding([.top, .horizontal], 12)
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
