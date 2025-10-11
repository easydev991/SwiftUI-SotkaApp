import SWDesignSystem
import SwiftUI

struct HomeFillProgressSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {}
            .background(Color.swCardBackground)
            .insideCardBackground()
    }
}

#if DEBUG
#Preview {
    HomeFillProgressSectionView()
        .padding()
}
#endif
