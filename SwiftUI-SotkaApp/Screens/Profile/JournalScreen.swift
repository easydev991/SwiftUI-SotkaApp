import SwiftUI

struct JournalScreen: View {
    let user: User

    var body: some View {
        Text("Journal")
            .navigationTitle("Journal")
    }
}

#Preview {
    JournalScreen(user: .init(from: .preview))
}
