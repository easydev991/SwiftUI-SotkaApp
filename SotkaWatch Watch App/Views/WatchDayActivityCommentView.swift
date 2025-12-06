import SwiftUI

/// Упрощенная версия DayActivityCommentView для Apple Watch
struct WatchDayActivityCommentView: View {
    @State private var isExpanded = false
    let comment: String?

    var body: some View {
        if let comment, !comment.isEmpty {
            Text(comment)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(isExpanded ? nil : 3)
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                }
        }
    }
}

#Preview("С комментарием") {
    WatchDayActivityCommentView(
        comment: "Отличная тренировка! Очень устал, но доволен результатом."
    )
}

#Preview("Без комментария") {
    WatchDayActivityCommentView(comment: nil)
}
