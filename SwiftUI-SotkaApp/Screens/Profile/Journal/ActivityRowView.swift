import SwiftUI

struct ActivityRowView: View {
    @ScaledMetric(relativeTo: .body) private var imageSize: CGFloat = 20
    let image: Image
    let title: String
    let count: Int?

    init(image: Image, title: String, count: Int? = nil) {
        self.image = image
        self.title = title
        self.count = count
    }

    var body: some View {
        HStack(spacing: 8) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .foregroundStyle(.blue)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let count {
                Text("\(count)")
            }
        }
    }
}

#if DEBUG
#Preview("С системной иконкой с счетчиком", traits: .sizeThatFitsLayout) {
    ActivityRowView(
        image: Image(systemName: "figure.play"),
        title: "Подтягивания",
        count: 10
    )
    .padding()
}

#Preview("С системной иконкой без счетчика", traits: .sizeThatFitsLayout) {
    ActivityRowView(
        image: Image(systemName: "figure.flexibility"),
        title: "Растяжка"
    )
    .padding()
}

#Preview("С ассетом с счетчиком", traits: .sizeThatFitsLayout) {
    ActivityRowView(
        image: Image(.pushups),
        title: "Отжимания",
        count: 25
    )
    .padding()
}

#Preview("С ассетом без счетчика", traits: .sizeThatFitsLayout) {
    ActivityRowView(
        image: Image(.pullups),
        title: "Подтягивания"
    )
    .padding()
}

#Preview("Малый размер шрифта", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        ActivityRowView(
            image: Image(systemName: "figure.play"),
            title: "Тренировка",
            count: 15
        )
        ActivityRowView(
            image: Image(.pushups),
            title: "Отжимания",
            count: 30
        )
    }
    .padding()
    .environment(\.dynamicTypeSize, .xSmall)
}

#Preview("Средний размер шрифта", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        ActivityRowView(
            image: Image(systemName: "figure.play"),
            title: "Тренировка",
            count: 15
        )
        ActivityRowView(
            image: Image(.pushups),
            title: "Отжимания",
            count: 30
        )
    }
    .padding()
    .environment(\.dynamicTypeSize, .medium)
}

#Preview("Большой размер шрифта", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        ActivityRowView(
            image: Image(systemName: "figure.play"),
            title: "Тренировка",
            count: 15
        )
        ActivityRowView(
            image: Image(.pushups),
            title: "Отжимания",
            count: 30
        )
    }
    .padding()
    .environment(\.dynamicTypeSize, .large)
}

#Preview("Очень большой размер шрифта", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        ActivityRowView(
            image: Image(systemName: "figure.play"),
            title: "Тренировка",
            count: 15
        )
        ActivityRowView(
            image: Image(.pushups),
            title: "Отжимания",
            count: 30
        )
    }
    .padding()
    .environment(\.dynamicTypeSize, .xxxLarge)
}

#Preview("Самый большой размер шрифта", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        ActivityRowView(
            image: Image(systemName: "figure.play"),
            title: "Тренировка",
            count: 15
        )
        ActivityRowView(
            image: Image(.pushups),
            title: "Отжимания",
            count: 30
        )
    }
    .padding()
    .environment(\.dynamicTypeSize, .accessibility5)
}
#endif
