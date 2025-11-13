import SWDesignSystem
import SwiftUI

struct WorkoutTimerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var startTime: Date?
    @State private var pausedTime: Date?
    @State private var remainingSeconds: Int
    @State private var shouldAnimate = true
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let duration: Int

    init(duration: Int) {
        self.duration = duration
        _remainingSeconds = State(initialValue: duration)
    }

    var body: some View {
        VStack(spacing: 12) {
            titleView
            Spacer()
            timerView
            Spacer()
            finishButton
        }
        .padding()
        .background(Color.swBackground)
        .onAppear {
            startTime = .now
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .onReceive(timer) { _ in
            updateRemainingSeconds()
            if remainingSeconds <= 0 {
                finishTimer()
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        guard let startTime else { return }

        switch (oldPhase, newPhase) {
        case (.active, .background), (.active, .inactive):
            // При сворачивании сохраняем время паузы
            pausedTime = .now
        case (.background, .active), (.inactive, .active):
            // При разворачивании вычисляем правильное время на основе реального прошедшего времени
            let elapsed = Date().timeIntervalSince(startTime)
            let newRemaining = max(0, duration - Int(elapsed))

            // Применяем без анимации для резкого перехода
            shouldAnimate = false
            remainingSeconds = newRemaining

            // Включаем анимацию обратно после небольшой задержки
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                shouldAnimate = true
            }

            pausedTime = nil
        default:
            break
        }
    }

    private func updateRemainingSeconds() {
        guard let startTime else { return }

        let elapsed: TimeInterval = if let pausedTime {
            // Если приложение свернуто, используем время до паузы
            pausedTime.timeIntervalSince(startTime)
        } else {
            // Если приложение активно, используем текущее время
            Date().timeIntervalSince(startTime)
        }

        let newRemaining = max(0, duration - Int(elapsed))
        remainingSeconds = newRemaining
    }

    private func finishTimer() {
        timer.upstream.connect().cancel()
        dismiss()
    }
}

private extension WorkoutTimerScreen {
    var titleView: some View {
        Text(.timerScreenTitle)
            .font(.largeTitle).bold()
    }

    var timerView: some View {
        CircularTimerView(
            remainingSeconds: remainingSeconds,
            totalSeconds: duration,
            shouldAnimate: shouldAnimate
        )
    }

    var finishButton: some View {
        Button(.timerScreenFinishButton, action: finishTimer)
            .buttonStyle(SWButtonStyle(mode: .tinted, size: .large))
    }
}

#Preview("10 сек") {
    WorkoutTimerScreen(duration: 10)
}
