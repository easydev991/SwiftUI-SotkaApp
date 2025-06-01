import SWDesignSystem
import SwiftUI

struct HomeScreen: View {
    @Environment(StatusManager.self) private var statusManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()
                if let calculator = statusManager.currentDayCalculator {
                    ScrollView {
                        DayCountView(calculator: calculator)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text("Loading")
                }
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("SOTKA")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeScreen()
        .environment(StatusManager())
}
