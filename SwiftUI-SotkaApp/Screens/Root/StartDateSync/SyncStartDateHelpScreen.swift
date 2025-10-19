import SWDesignSystem
import SwiftUI

struct SyncStartDateHelpScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(.dateSyncHelpIntroduction)
                VStack(alignment: .leading, spacing: 8) {
                    Text(.dateSyncHelpAppChoiceTitle)
                        .font(.title3).bold()
                    Text(.dateSyncHelpAppChoiceDescription)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(.dateSyncHelpSiteChoiceTitle)
                        .font(.title3).bold()
                    Text(.dateSyncHelpSiteChoiceDescription)
                }
                SWDivider()
                Text(.dateSyncHelpSummary)
                Text(.dateSyncHelpWarning)
                    .fontWeight(.medium)
            }
            .padding()
        }
        .navigationTitle(.dateSyncHelpTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SyncStartDateHelpScreen()
    }
}
