import SWDesignSystem
import SwiftData
import SwiftUI

/// Экран списка пользовательских упражнений
struct CustomExercisesScreen: View {
    @Query private var customExercises: [CustomExercise]
    @Environment(\.modelContext) private var modelContext
    @State private var searchQuery = ""
    @State private var sortOrder = SortOrder.modifyDate
    @State private var exerciseToDelete: CustomExercise?
    @State private var editExercise: CustomExercise?
    @State private var showAddExerciseSheet = false

    var body: some View {
        ZStack {
            if customExercises.isEmpty {
                emptyStateView
                    .transition(.scale.combined(with: .opacity))
            } else {
                exercisesListView
                    .overlay { emptySearchViewIfNeeded }
            }
        }
        .animation(.bouncy, value: customExercises.isEmpty)
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .automatic))
        .toolbar {
            if !customExercises.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    sortButton
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddExerciseSheet.toggle() } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .background(Color.swBackground)
        .navigationTitle("Custom exercises")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $editExercise) { exercise in
            ScrollView {
                EditCustomExerciseScreen(oldItem: exercise) {
                    editExercise = nil
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
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
                Button("Edit") {
                    editExercise = exercise
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
                if let exercise = exerciseToDelete {
                    modelContext.delete(exercise)
                    exerciseToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                exerciseToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete \"\(exerciseToDelete?.name ?? "")\"? This action cannot be undone.")
        }
    }

    var filteredExercises: [CustomExercise] {
        let exercises = if searchQuery.isEmpty {
            customExercises
        } else {
            customExercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        return exercises.sorted { exercise1, exercise2 in
            switch sortOrder {
            case .modifyDate:
                exercise1.modifyDate > exercise2.modifyDate
            case .name:
                exercise1.name.localizedCaseInsensitiveCompare(exercise2.name) == .orderedAscending
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

    var sortButton: some View {
        Menu {
            Picker("Sort Order", selection: $sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Text(order.title)
                        .tag(order)
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
        .accessibilityIdentifier("sortButton")
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
}

private extension CustomExercisesScreen {
    /// Порядок сортировки упражнений
    enum SortOrder: CaseIterable {
        case modifyDate
        case name

        var title: LocalizedStringKey {
            switch self {
            case .modifyDate: "Date modified"
            case .name: "Name"
            }
        }
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
