import SwiftUI

struct ProgressScreen: View {
    let user: User

    var body: some View {
        Text("Progress")
            .navigationTitle("Progress")
    }
}

#Preview {
    ProgressScreen(user: .init(from: .preview))
}
