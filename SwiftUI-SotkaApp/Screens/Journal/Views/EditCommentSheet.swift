import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

/// Модальное окно для редактирования комментария к активности дня
struct EditCommentSheet: View {
    @Bindable var activity: DayActivity
    @FocusState private var isFocused: Bool
    @State private var textModel = CommentEditModel()
    @Environment(DailyActivitiesService.self) private var activitiesService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var commentBinding: Binding<String> {
        .init(
            get: { activity.comment ?? "" },
            set: { newValue in
                activity.comment = newValue.isEmpty ? nil : newValue
            }
        )
    }

    var body: some View {
        ContentInSheet(title: String(localized: .dayActivityCommentTitle)) {
            VStack {
                SWTextEditor(
                    text: commentBinding,
                    placeholder: String(localized: .dayActivityCommentPlaceholder),
                    isFocused: isFocused,
                    height: 200
                )
                .focused($isFocused)
                .task {
                    if textModel.initialComment == nil {
                        textModel.initialComment = activity.comment
                    }
                    guard !isFocused else { return }
                    try? await Task.sleep(nanoseconds: 750_000_000)
                    isFocused = true
                }
                Spacer()
                saveButton
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color.swBackground)
    }
}

private extension EditCommentSheet {
    var saveButton: some View {
        Button(.dayActivityCommentSave) {
            isFocused = false
            activitiesService.updateComment(
                day: activity.day,
                comment: activity.comment,
                context: modelContext
            )
            dismiss()
        }
        .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
        .disabled(!textModel.canSave(activity.comment))
    }
}

#if DEBUG
#Preview("Есть комментарий (день 7)") {
    let user = User.preview
    let container = PreviewModelContainer.make(with: user)
    if let activity = user.dayActivities.first(where: { $0.day == 7 }) ?? user.dayActivities.first {
        EditCommentSheet(activity: activity)
            .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
            .modelContainer(container)
    } else {
        Text("Нет активностей для предпросмотра")
    }
}

#Preview("Нет комментария (день 1)") {
    let user = User.preview
    let container = PreviewModelContainer.make(with: user)
    if let activity = user.dayActivities.first {
        EditCommentSheet(activity: activity)
            .environment(DailyActivitiesService(client: MockDaysClient(result: .success)))
            .modelContainer(container)
    } else {
        Text("Нет активностей для предпросмотра")
    }
}
#endif
