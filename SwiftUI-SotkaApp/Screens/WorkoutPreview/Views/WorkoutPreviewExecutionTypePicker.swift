import SwiftUI
import SWUtils

struct WorkoutPreviewExecutionTypePicker: View {
    @Binding var selection: ExerciseExecutionType?
    let availableTypes: [ExerciseExecutionType]

    var body: some View {
        Picker(.exerciseExecutionType, selection: $selection) {
            ForEach(availableTypes, id: \.self) { type in
                Text(type.localizedTitle).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
}

#if DEBUG
#Preview("Все варианты") {
    @Previewable @State var selection: ExerciseExecutionType? = .cycles
    WorkoutPreviewExecutionTypePicker(
        selection: $selection,
        availableTypes: [.cycles, .sets, .turbo]
    )
}
#endif
