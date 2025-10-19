import SwiftUI

struct JournalScreen: View {
    let user: User

    var body: some View {
        Text(.journal)
            .navigationTitle(.journal)
    }
}

#Preview {
    JournalScreen(user: .init(from: .preview))
}
