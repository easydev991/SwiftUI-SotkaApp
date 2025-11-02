import SwiftData
import SwiftUI

struct JournalGridView: View {
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.modelContext) private var modelContext
    let user: User

    var body: some View {
        VStack {}
    }
}

#if DEBUG
#Preview {
    JournalGridView(user: .preview)
        .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
}
#endif
