import SwiftData
import SwiftUI

struct SyncJournalScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SyncJournalEntry.startDate, order: .reverse)
    private var entries: [SyncJournalEntry]
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            if entries.isEmpty {
                ContentUnavailableView(
                    .noEntries,
                    systemImage: "tray",
                    description: Text(.syncJournalEmptyStateDescription)
                )
            } else {
                List {
                    ForEach(DateGroup.groupEntriesByDate(entries)) { group in
                        Section(group.localizedTitle) {
                            ForEach(group.entries) { entry in
                                NavigationLink(destination: SyncJournalEntryDetailsScreen(entry: entry)) {
                                    SyncJournalRowView(entry: entry)
                                }
                                .disabled(entry.endDate == nil)
                            }
                        }
                    }
                }
            }
        }
        .animation(.default, value: entries.isEmpty)
        .navigationTitle(.syncJournal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !entries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    deleteAllButton
                }
            }
        }
    }

    private var deleteAllButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            Label(.syncJournalDeleteAll, systemImage: "trash")
        }
        .confirmationDialog(
            .syncJournalConfirmDeleteAllTitle,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(.commonDelete, role: .destructive) {
                deleteAllEntries()
            }
        } message: {
            Text(.syncJournalConfirmDeleteAllMessage)
        }
    }

    private func deleteAllEntries() {
        for entry in entries {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SyncJournalScreen()
            .modelContainer(PreviewModelContainer.make(with: .preview))
    }
}
#endif
