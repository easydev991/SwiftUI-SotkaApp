import SWDesignSystem
import SwiftUI

struct HomeScreen: View {
    @Environment(StatusManager.self) private var statusManager

    var body: some View {
        NavigationStack {
            @Bindable var statusManager = statusManager
            ZStack {
                Color.swBackground.ignoresSafeArea()
                if let calculator = statusManager.currentDayCalculator {
                    ScrollView {
                        VStack(spacing: 12) {
                            DayCountView(calculator: calculator)
                            makeInfopostView(with: calculator)
                            HomeActivitySection()
//                            HomeProgressSection()
                        }
                        .padding([.horizontal, .bottom])
                    }
                } else {
                    Text("Loading")
                }
            }
            .frame(maxWidth: .infinity)
            .sheet(item: $statusManager.conflictingSyncModel) { model in
                SyncStartDateView(model: model)
            }
            .navigationTitle("SOTKA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: InfopostsListScreen()) {
                        Text("Infoposts")
                    }
                }
            }
        }
    }
}

private extension HomeScreen {
    @ViewBuilder
    func makeInfopostView(with calculator: DayCalculator) -> some View {
        let service = statusManager.infopostsService
        if let infopost = try? service.getInfopost(forDay: calculator.currentDay) {
            DailyInfopostView(
                currentDay: calculator.currentDay,
                infopost: infopost
            )
        }
    }
}

#if DEBUG
#Preview {
    HomeScreen()
        .environment(
            StatusManager(
                customExercisesService: .init(
                    client: MockExerciseClient(result: .success)
                ),
                infopostsService: .init(
                    language: "ru",
                    infopostsClient: MockInfopostsClient(result: .success)
                )
            )
        )
        .modelContainer(PreviewModelContainer.make(with: User(id: 1)))
}
#endif
