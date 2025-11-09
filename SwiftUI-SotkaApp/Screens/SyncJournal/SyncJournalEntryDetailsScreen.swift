import SwiftUI

struct SyncJournalEntryDetailsScreen: View {
    let entry: SyncJournalEntry

    var body: some View {
        List {
            Section(.generalInformation) {
                HStack {
                    Text(.syncJournalDetailScreenStartDate)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(formatDate(entry.startDate))
                        .foregroundStyle(.secondary)
                }
                if let endDate = entry.endDate {
                    HStack {
                        Text(.endDate)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(formatDate(endDate))
                            .foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Text(.syncJournalDetailScreenResult)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    SyncResultBadge(
                        isInProgress: entry.endDate == nil,
                        result: entry.result
                    )
                }
                if let duration = entry.duration {
                    HStack {
                        Text(.duration)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(formatDuration(duration))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            detailsView
        }
        .navigationTitle(formatDateForTitle(entry.startDate))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension SyncJournalEntryDetailsScreen {
    @ViewBuilder
    var detailsView: some View {
        if let details = entry.details {
            ForEach(details.sections) { section in
                Section(section.localizedTitle) {
                    switch section {
                    case let .statistics(items):
                        ForEach(items) { item in
                            statsSection(title: item.title, stats: item.stats)
                        }
                    case let .errors(errors):
                        ForEach(errors) { error in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(error.message)
                                if let description = error.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func statsSection(title: String, stats: SyncStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(stats.items) { item in
                    HStack {
                        Text(item.localizedTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(stats.value(for: item))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .none
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }

    func formatDateForTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(localized: .sec(Float(duration)))
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(localized: .minSec(minutes, seconds))
        }
    }
}

#if DEBUG
#Preview("С полной статистикой") {
    NavigationStack {
        SyncJournalEntryDetailsScreen(entry: .previewWithFullStats)
    }
}

#Preview("С ошибками") {
    NavigationStack {
        SyncJournalEntryDetailsScreen(entry: .previewWithMultipleErrors)
    }
}

#Preview("Без деталей") {
    NavigationStack {
        SyncJournalEntryDetailsScreen(entry: .previewWithoutDetails)
    }
}

#Preview("С частичными данными") {
    NavigationStack {
        SyncJournalEntryDetailsScreen(entry: .previewWithPartialData)
    }
}

#Preview("В процессе синхронизации") {
    NavigationStack {
        SyncJournalEntryDetailsScreen(entry: .previewInProgress)
    }
}

#Preview("Только ошибки без статистики") {
    NavigationStack {
        SyncJournalEntryDetailsScreen(entry: .previewErrorsOnly)
    }
}
#endif
