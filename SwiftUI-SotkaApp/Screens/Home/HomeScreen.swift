import SWDesignSystem
import SwiftData
import SwiftUI

struct HomeScreen: View {
    @Environment(StatusManager.self) private var statusManager
    @Query private var users: [User]
    private var user: User? { users.first }

    var body: some View {
        NavigationStack {
            @Bindable var statusManager = statusManager
            ZStack {
                Color.swBackground.ignoresSafeArea()
                if let calculator = statusManager.currentDayCalculator, let user {
                    ScrollView {
                        VStack(spacing: 12) {
                            HomeDayCountView(calculator: calculator)
                            makeInfopostView(with: calculator)
                            HomeActivitySectionView()
                            makeFillProgressView(with: calculator, user: user)
                        }
                        .padding()
                    }
                } else {
                    Text(.loading)
                }
            }
            .frame(maxWidth: .infinity)
            .sheet(item: $statusManager.conflictingSyncModel) { model in
                SyncStartDateView(model: model)
            }
            .navigationTitle(.sotka)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: InfopostsListScreen()) {
                        Text(.infoposts)
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
            HomeInfopostSectionView(
                currentDay: calculator.currentDay,
                infopost: infopost
            )
        }
    }

    func makeFillProgressView(with calculator: DayCalculator, user: User) -> some View {
        HomeFillProgressSectionView(
            currentDay: calculator.currentDay,
            user: user
        )
    }
}

#if DEBUG
#Preview {
    HomeScreen()
        .environment(StatusManager.preview)
        .modelContainer(PreviewModelContainer.make(with: User(id: 1)))
}
#endif
