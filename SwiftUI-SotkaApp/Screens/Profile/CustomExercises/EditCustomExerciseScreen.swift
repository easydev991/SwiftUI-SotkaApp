import OSLog
import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

/// Универсальный экран для создания и редактирования пользовательского упражнения
struct EditCustomExerciseScreen: View {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: EditCustomExerciseScreen.self)
    )
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [CustomExercise]
    @State private var exerciseName = ""
    @State private var selectedImageId: Int = -1
    @FocusState private var isFirstFieldFocused
    private let oldItem: CustomExercise?
    private let closeAction: () -> Void

    init(
        oldItem: CustomExercise? = nil,
        closeAction: @escaping () -> Void
    ) {
        self.oldItem = oldItem
        self.closeAction = closeAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            exerciseNameSection
            iconSection
            Spacer()
        }
        .padding()
        .background(Color.swBackground)
        .navigationTitle("Exercise")
        .navigationBarBackButtonHidden(oldItem != nil)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let oldItem {
                exerciseName = oldItem.name
                selectedImageId = oldItem.imageId
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(backButtonTitle) {
                    isFirstFieldFocused = false
                    closeAction()
                }
                .accessibilityIdentifier(backButtonAccessibilityIdentifier)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                    closeAction()
                }
                .disabled(!canSave)
                .accessibilityIdentifier("saveExerciseNavButton")
            }
        }
    }

    private var exerciseNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercise name")
                .font(.headline)
                .foregroundStyle(.secondary)

            TextField("Enter exercise name", text: $exerciseName)
                .textFieldStyle(.roundedBorder)
                .focused($isFirstFieldFocused)
                .onAppear { isFirstFieldFocused = true }
        }
        .accessibilityElement()
        .accessibilityLabel("Exercise name")
        .accessibilityValue(exerciseName)
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose icon")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [
                    .init(
                        .adaptive(minimum: 40),
                        spacing: 16,
                        alignment: .leading
                    )
                ],
                spacing: 16
            ) {
                ForEach(
                    ExerciseType.CustomType.allCases,
                    id: \.rawValue,
                    content: makeIconButton
                )
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Exercise icon")
    }

    private var backButtonTitle: LocalizedStringKey {
        oldItem == nil ? "Close" : "Cancel"
    }

    private var backButtonAccessibilityIdentifier: String {
        oldItem == nil ? "closeButton" : "cancelButton"
    }

    private var isDuplicate: Bool {
        allExercises.contains { exercise in
            exercise.id != oldItem?.id && exercise.name.localizedCaseInsensitiveCompare(exerciseName) == .orderedSame
        }
    }

    private var canSave: Bool {
        let isNameEmpty = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return if let oldItem {
            !isNameEmpty
                && !isDuplicate
                && (exerciseName != oldItem.name || selectedImageId != oldItem.imageId)
        } else {
            !isNameEmpty && selectedImageId != -1 && !isDuplicate
        }
    }

    private var canSaveExercise: Bool {
        !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImageId != -1
    }

    private func save() {
        guard let oldItem else {
            let newExercise = newExercise
            modelContext.insert(newExercise)
            return
        }
        oldItem.name = exerciseName
        oldItem.imageId = selectedImageId
        oldItem.modifyDate = .now
    }

    private var newExercise: CustomExercise {
        CustomExercise(
            id: UUID().uuidString,
            name: exerciseName,
            imageId: selectedImageId,
            createDate: .now,
            modifyDate: .now
        )
    }
}

extension EditCustomExerciseScreen {
    struct Model {
        var exerciseName = ""
        var selectedImageId: Int = -1

        var canSaveExercise: Bool {
            !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImageId != -1
        }

        var newExercise: CustomExercise {
            CustomExercise(
                id: UUID().uuidString,
                name: exerciseName,
                imageId: selectedImageId,
                createDate: .now,
                modifyDate: .now
            )
        }
    }
}

private extension EditCustomExerciseScreen {
    func makeIconButton(for customType: ExerciseType.CustomType) -> some View {
        let isSelected = selectedImageId == customType.rawValue
        return Button {
            withAnimation {
                selectedImageId = customType.rawValue
            }
        } label: {
            customType.image
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.swAccent : .swSeparators,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .disabled(isSelected)
    }
}

#if DEBUG
#Preview("Create") {
    NavigationStack {
        EditCustomExerciseScreen {}
            .modelContainer(PreviewModelContainer.make(with: User(id: 1)))
    }
}

#Preview("Edit") {
    NavigationStack {
        EditCustomExerciseScreen(
            oldItem: .init(
                id: "test",
                name: "Test Exercise",
                imageId: 1,
                createDate: .now,
                modifyDate: .now
            ),
            closeAction: {}
        )
        .modelContainer(PreviewModelContainer.make(with: User(id: 1)))
    }
}
#endif
