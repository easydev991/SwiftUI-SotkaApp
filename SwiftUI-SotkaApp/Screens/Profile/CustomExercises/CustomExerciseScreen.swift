import SwiftUI

/// Экран просмотра пользовательского упражнения
struct CustomExerciseScreen: View {
    @State private var isEditing = false
    let exercise: CustomExercise

    var body: some View {
        ScrollView {
            ZStack {
                if isEditing {
                    EditCustomExerciseScreen(oldItem: exercise) { isEditing = false }
                        .transition(
                            .move(edge: .trailing)
                                .combined(with: .scale)
                                .combined(with: .opacity)
                        )
                } else {
                    regularView
                        .transition(
                            .move(edge: .leading)
                                .combined(with: .scale)
                                .combined(with: .opacity)
                        )
                }
            }
            .animation(.default, value: isEditing)
            .navigationBarTitleDisplayMode(.inline)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var regularView: some View {
        VStack(alignment: .leading, spacing: 20) {
            titleSection
            iconSection
            datesSection
            Spacer()
        }
        .padding()
        .navigationTitle(.exercise)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(.edit) { isEditing.toggle() }
                    .accessibilityIdentifier("editButton")
            }
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            makeSectionHeader("Exercise name")
            Text(exercise.name)
                .font(.title2)
                .fontWeight(.medium)
        }
        .accessibilityElement()
        .accessibilityLabel(.exerciseName)
        .accessibilityValue(exercise.name)
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            makeSectionHeader(String(localized: .icon))
            exercise.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .padding(16)
                .clipShape(.rect(cornerRadius: 12))
        }
        .accessibilityElement()
        .accessibilityLabel(.exerciseIcon)
    }

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            makeSectionHeader(String(localized: .dates))
            VStack(alignment: .leading, spacing: 8) {
                makeDateRow(label: String(localized: .created), date: exercise.createDate)
                makeDateRow(label: String(localized: .modified), date: exercise.modifyDate)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(.exerciseDates)
    }
}

private extension CustomExerciseScreen {
    func makeSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
    }

    func makeDateRow(label: String, date: Date) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(date, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                .fontWeight(.medium)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CustomExerciseScreen(exercise: CustomExercise(
            id: "test",
            name: "Test Exercise",
            imageId: 1,
            createDate: .now,
            modifyDate: .now
        ))
    }
}
#endif
