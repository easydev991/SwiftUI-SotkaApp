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
}
