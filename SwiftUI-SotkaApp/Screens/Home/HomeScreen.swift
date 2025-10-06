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
                        VStack(spacing: 16) {
                            DayCountView(calculator: calculator)
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
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

#Preview {
    HomeScreen()
        .environment(
            StatusManager(
                customExercisesService: CustomExercisesService(
                    client: MockExerciseClient(result: .success)
                )
            )
        )
}
