import SwiftUI

struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .environment(\.isLoading, isLoading)
                .opacity(isLoading ? 0.5 : 1)
                .disabled(isLoading)
            if isLoading {
                LoadingIndicator()
            }
        }
        .animation(.default, value: isLoading)
    }
}

private struct LoadingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0.1, to: 1.0)
            .stroke(
                AngularGradient(
                    gradient: .init(
                        stops: [
                            .init(color: Color.swAccent.opacity(0), location: 0.0),
                            .init(color: Color.swAccent, location: 1.0)
                        ]
                    ),
                    center: .center,
                    startAngle: .degrees(36), // 10% от 360°
                    endAngle: .degrees(360)
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .frame(width: 50, height: 50)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 2.0).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

#if DEBUG
#Preview {
    Text("Загрузка...").loadingOverlay(if: true)
}
#endif
