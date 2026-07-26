import SwiftUI

struct SWDivider: View {
    init() {}

    var body: some View {
        Divider().background(Color.swSeparators)
    }
}

#if DEBUG
#Preview { SWDivider() }
#endif
