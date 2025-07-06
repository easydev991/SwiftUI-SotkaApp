import SWDesignSystem
import SwiftData
import SwiftUI

struct CustomExercisesScreen: View {
    @Query private var customExercises: [CustomExercise]

    var body: some View {
        List(customExercises, id: \.id) { exercise in
            HStack {
                exercise.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                Text(exercise.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .listStyle(.plain)
        .background(Color.swBackground)
        .navigationTitle("Custom exercises")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CustomExercisesScreen()
            .modelContainer(PreviewModelContainer.make(with: User(id: 1)))
    }
}
#endif
