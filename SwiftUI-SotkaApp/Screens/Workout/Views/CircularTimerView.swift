import SWDesignSystem
import SwiftUI

struct CircularTimerView: View {
    let remainingSeconds: Int
    let totalSeconds: Int
    let shouldAnimate: Bool

    init(remainingSeconds: Int, totalSeconds: Int, shouldAnimate: Bool = true) {
        self.remainingSeconds = remainingSeconds
        self.totalSeconds = totalSeconds
        self.shouldAnimate = shouldAnimate
    }

    var body: some View {
        ZStack {
            backgroundCircle
            foregroundCircle
            timerTextView
        }
        .frame(maxWidth: 250, maxHeight: 250)
    }
}

private extension CircularTimerView {
    var progress: CGFloat {
        .init(totalSeconds - remainingSeconds) / CGFloat(totalSeconds)
    }

    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var backgroundCircle: some View {
        Circle()
            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
    }

    var foregroundCircle: some View {
        Circle()
            .trim(from: 0, to: 1.0 - progress)
            .stroke(
                Color.swAccent,
                style: StrokeStyle(lineWidth: 8, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .animation(shouldAnimate ? .linear(duration: 1.0) : nil, value: remainingSeconds)
    }

    var timerTextView: some View {
        Text(timeString)
            .font(.largeTitle).bold()
            .monospacedDigit() // Для предотвращения "прыжков" цифр
    }
}

#Preview {
    CircularTimerView(remainingSeconds: 45, totalSeconds: 60)
}

#Preview("Без анимации") {
    CircularTimerView(remainingSeconds: 45, totalSeconds: 60, shouldAnimate: false)
}
