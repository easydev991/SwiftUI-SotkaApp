import SWDesignSystem
import SwiftUI

struct SyncStartDateHelpScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("DateSync.Help.Introduction")
                VStack(alignment: .leading, spacing: 8) {
                    Text("DateSync.Help.AppChoiceTitle")
                        .font(.title3).bold()
                    Text("DateSync.Help.AppChoiceDescription")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("DateSync.Help.SiteChoiceTitle")
                        .font(.title3).bold()
                    Text("DateSync.Help.SiteChoiceDescription")
                }
                SWDivider()
                Text("DateSync.Help.Summary")
                Text("DateSync.Help.Warning")
                    .fontWeight(.medium)
            }
            .padding()
        }
        .navigationTitle("DateSync.Help.Title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SyncStartDateHelpScreen()
    }
}
