import SWDesignSystem
import SwiftUI

struct HomeFillProgressSectionView: View {
    private let model: Model
    private let user: User

    init(currentDay: Int, user: User) {
        self.model = .init(currentDay: currentDay, user: user)
        self.user = user
    }

    var body: some View {
        if model.shouldShowFillProgress {
            HomeSectionView(title: "Home.Progress") {
                NavigationLink {
                    ProgressScreen(user: user)
                } label: {
                    HStack {
                        Text("Home.FillResults")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ChevronView()
                    }
                    .padding([.horizontal, .bottom], 12)
                }
            }
        }
    }
}

extension HomeFillProgressSectionView {
    struct Model {
        let shouldShowFillProgress: Bool

        init(currentDay: Int, user: User) {
            self.shouldShowFillProgress = !user.isMaximumsFilled(for: currentDay)
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        // Превью когда нужно показать секцию (нет прогресса)
        HomeFillProgressSectionView(currentDay: 25, user: .preview)

        // Превью когда не нужно показывать секцию (есть прогресс)
        HomeFillProgressSectionView(currentDay: 25, user: .previewWithProgress)
    }
    .padding()
    .modelContainer(PreviewModelContainer.make(with: .preview))
}
#endif
