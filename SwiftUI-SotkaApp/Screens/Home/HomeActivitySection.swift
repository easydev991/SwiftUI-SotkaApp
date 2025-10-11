import SWDesignSystem
import SwiftUI

struct HomeActivitySection: View {
    var body: some View {
        HomeSectionView(title: "Activity") {
            HStack(spacing: 12) {
                ForEach(DayActivityType.allCases, id: \.self) {
                    makeView(for: $0)
                }
            }
            .padding([.horizontal, .bottom], 12)
        }
    }
}

private extension HomeActivitySection {
    func makeView(
        for activityType: DayActivityType
    ) -> some View {
        Button {
            print("TODO: выбрали активность \(activityType)")
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(activityType.color)
                    .frame(maxHeight: 80)
                    .overlay {
                        Image(systemName: activityType.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.white)
                    }
                Text(activityType.localizedTitle)
                    .fixedSize()
                    .font(.footnote)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
#Preview {
    HomeActivitySection()
        .padding()
}
#endif
