import SwiftUI

struct SyncResultBadge: View {
    let isInProgress: Bool
    let result: SyncResultType

    var body: some View {
        HStack(spacing: 4) {
            if isInProgress {
                Text(.syncJournalRowViewInProgress)
            } else {
                Text(result.localizedTitle)
                Image(systemName: result.systemImageName)
                    .symbolVariant(.circle.fill)
                    .foregroundStyle(result.color)
            }
        }
        .foregroundStyle(.secondary)
    }
}

#if DEBUG
#Preview("В процессе") {
    SyncResultBadge(isInProgress: true, result: .success)
}

#Preview("Успех") {
    SyncResultBadge(isInProgress: false, result: .success)
}

#Preview("Частично") {
    SyncResultBadge(isInProgress: false, result: .partial)
}

#Preview("Ошибка") {
    SyncResultBadge(isInProgress: false, result: .error)
}
#endif
