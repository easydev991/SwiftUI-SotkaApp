import SwiftUI

struct SyncJournalRowView: View {
    let entry: SyncJournalEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.formatTimeWithMilliseconds(entry.startDate))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let summaryText = entry.details?.summaryText {
                    Text(summaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            SyncResultBadge(
                isInProgress: entry.endDate == nil,
                result: entry.result
            )
        }
        .animation(.default, value: entry)
    }

    static func formatTimeWithMilliseconds(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#if DEBUG
#Preview("Успешная синхронизация с деталями") {
    SyncJournalRowView(entry: .previewSuccessWithDetails)
        .padding()
}

#Preview("Частичная синхронизация с ошибками") {
    SyncJournalRowView(entry: .previewPartialWithErrors)
        .padding()
}

#Preview("Ошибка синхронизации") {
    SyncJournalRowView(entry: .previewError)
        .padding()
}

#Preview("В процессе синхронизации") {
    SyncJournalRowView(entry: .previewInProgress)
        .padding()
}

#Preview("Без деталей") {
    SyncJournalRowView(entry: .previewWithoutDetails)
        .padding()
}
#endif
