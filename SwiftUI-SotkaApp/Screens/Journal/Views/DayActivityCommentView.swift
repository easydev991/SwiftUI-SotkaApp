import SwiftUI

struct DayActivityCommentView: View {
    @State private var isExpanded = false
    let comment: String?

    var body: some View {
        if let comment, !comment.isEmpty {
            Text(comment)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(isExpanded ? nil : 3)
            #if !os(watchOS)
                .textSelection(.enabled)
            #endif
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                }
        }
    }
}

#if DEBUG
#Preview("С комментарием") {
    DayActivityCommentView(
        comment: "Отличная тренировка! Очень устал, но доволен результатом. Сегодня выполнил все упражнения по программе. Особенно горжусь тем, что смог сделать больше подтягиваний, чем в прошлый раз. Завтра планирую продолжить тренировки и улучшить свой результат еще больше."
    )
}

#Preview("Без комментария") {
    DayActivityCommentView(comment: nil)
}
#endif
