import OSLog
import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

/// Экран добавления пользовательского упражнения
struct AddCustomExerciseScreen: View {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AddCustomExerciseScreen.self)
    )

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var exerciseName = ""
    @State private var selectedImageId = -1

    private var isDuplicate: Bool {
        guard !exerciseName.isEmpty,
              let exercises = try? modelContext.fetch(FetchDescriptor<CustomExercise>()),
              !exercises.isEmpty
        else {
            return false
        }
        return exercises.contains { $0.name == exerciseName && $0.imageId == selectedImageId }
    }

    private var canSaveExercise: Bool {
        !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDuplicate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TextField("Enter exercise name", text: $exerciseName)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose icon").font(.headline)

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
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.swBackground)
        .navigationTitle("New exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: saveExercise)
                    .disabled(!canSaveExercise)
            }
        }
    }

    private func saveExercise() {
        let newExercise = CustomExercise(
            id: UUID().uuidString,
            name: exerciseName,
            imageId: selectedImageId,
            createDate: .now,
            modifyDate: .now
        )
        modelContext.insert(newExercise)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            SWAlert.shared.presentDefaultUIKit(error)
            logger.error("Ошибка сохранения упражнения: \(error.localizedDescription)")
        }
    }
}

private extension AddCustomExerciseScreen {
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
#Preview {
    NavigationStack {
        AddCustomExerciseScreen()
            .modelContainer(PreviewModelContainer.make(with: User(id: 1)))
    }
}
#endif
