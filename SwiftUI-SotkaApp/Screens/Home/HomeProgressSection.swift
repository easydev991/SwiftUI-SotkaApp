import SWDesignSystem
import SwiftUI

struct HomeProgressSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {}
            .background(Color.swCardBackground)
            .insideCardBackground()
    }
}

#if DEBUG
#Preview {
    HomeProgressSection()
        .padding()
}
#endif
