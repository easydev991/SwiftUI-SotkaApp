import SWDesignSystem
import SwiftUI

struct CustomExercisesScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // TODO: Добавить отображение пользовательских упражнений
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.swBackground)
        .navigationTitle("Custom exercises")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CustomExercisesScreen()
    }
}
#endif
