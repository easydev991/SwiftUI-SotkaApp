import OSLog
import SWDesignSystem
import SwiftData
import SwiftUI

/// Экран списка пользовательских упражнений
struct CustomExercisesScreen: View {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CustomExercisesScreen.self)
    )
    @Query(FetchDescriptor<CustomExercise>(predicate: #Predicate { !$0.shouldDelete }))
    private var customExercises: [CustomExercise]
    @Environment(\.modelContext) private var modelContext
    @Environment(CustomExercisesService.self) private var customExercisesService
    @State private var searchQuery = ""
    @State private var exerciseToDelete: CustomExercise?
    @State private var showAddExerciseSheet = false

    var body: some View {
        ZStack {
            if customExercises.isEmpty {
                emptyStateView
                    .transition(.scale.combined(with: .opacity))
            } else {
                exercisesListView
                    .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .automatic))
                    .overlay { emptySearchViewIfNeeded }
            }
        }
        .animation(.bouncy, value: customExercises.isEmpty)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddExerciseSheet.toggle() } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .background(Color.swBackground)
        .navigationTitle("Custom exercises")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddExerciseSheet) {
            NavigationStack {
                ScrollView {
                    EditCustomExerciseScreen { showAddExerciseSheet.toggle() }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }
}

private extension CustomExercisesScreen {
    var exercisesListView: some View {
        List(filteredExercises, id: \.id) { exercise in
            NavigationLink(destination: CustomExerciseScreen(exercise: exercise)) {
                HStack {
                    exercise.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                    Text(exercise.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .swipeActions {
                Button("Delete", role: .destructive) {
                    exerciseToDelete = exercise
                }
            }
        }
        .listStyle(.plain)
        .confirmationDialog(
            "Delete Exercise",
            isPresented: .constant(exerciseToDelete != nil),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let exerciseToDelete {
                    deleteExercise(exerciseToDelete)
                }
            }
            Button("Cancel", role: .cancel) {
                exerciseToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete \"\(exerciseToDelete?.name ?? "")\"? This action cannot be undone.")
        }
        .loadingOverlay(if: customExercisesService.isLoading)
    }

    var filteredExercises: [CustomExercise] {
        if searchQuery.isEmpty {
            customExercises
        } else {
            customExercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    var emptyStateView: some View {
        ContentUnavailableView(
            label: { Label("No custom exercises yet", systemImage: "figure.mixed.cardio") },
            description: { Text("Create your first custom exercise") },
            actions: {
                Button { showAddExerciseSheet.toggle() } label: {
                    Label("Create exercise", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("emptyStateView")
    }

    var emptySearchViewIfNeeded: some View {
        ZStack {
            if filteredExercises.isEmpty, !searchQuery.isEmpty {
                ContentUnavailableView.search
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.bouncy, value: filteredExercises.isEmpty && !searchQuery.isEmpty)
    }

    func deleteExercise(_ exercise: CustomExercise) {
        do {
            try customExercisesService.deleteCustomExercise(
                exercise,
                context: modelContext
            )
        } catch {
            logger.error("Ошибка удаления упражнения: \(error)")
        }
        exerciseToDelete = nil
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CustomExercisesScreen()
            .modelContainer(PreviewModelContainer.make(with: User(id: 1)))
            .environment(CustomExercisesService(client: MockExerciseClient(result: .success)))
    }
}
#endif
