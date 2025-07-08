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

    @State private var model = Model()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TextField("Enter exercise name", text: $model.exerciseName)
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
                    .disabled(!model.canSaveExercise)
                    .animation(.default, value: model.canSaveExercise)
            }
        }
        .onAppear(perform: fetchExercises)
    }

    private func fetchExercises() {
        let descriptor = FetchDescriptor<CustomExercise>()
        model.allExercises = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func saveExercise() {
        let newExercise = model.newExercise
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

extension AddCustomExerciseScreen {
    struct Model {
        var exerciseName = ""
        var selectedImageId: Int = -1
        var allExercises = [CustomExercise]()

        /// Проверка на дубликат среди всех упражнений
        var isDuplicate: Bool {
            guard !exerciseName.isEmpty, !allExercises.isEmpty else { return false }
            return allExercises.contains { $0.name == exerciseName && $0.imageId == selectedImageId }
        }

        /// Можно ли сохранить упражнение
        var canSaveExercise: Bool {
            !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !isDuplicate
                && selectedImageId != -1
        }

        var newExercise: CustomExercise {
            .init(
                id: UUID().uuidString,
                name: exerciseName,
                imageId: selectedImageId,
                createDate: .now,
                modifyDate: .now
            )
        }
    }
}

private extension AddCustomExerciseScreen {
    func makeIconButton(for customType: ExerciseType.CustomType) -> some View {
        let isSelected = model.selectedImageId == customType.rawValue
        return Button {
            withAnimation {
                model.selectedImageId = customType.rawValue
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
