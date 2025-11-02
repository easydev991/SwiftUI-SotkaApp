import SwiftData
import SwiftUI

struct JournalGridView: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.modelContext) private var modelContext
    let user: User

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#if DEBUG
#Preview {
    JournalGridView(user: .preview)
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
}
#endif
