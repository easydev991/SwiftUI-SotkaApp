import Combine
import SwiftUI

/// Упрощенная версия таймера отдыха для Apple Watch
struct WorkoutRestTimerView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @State private var startTime: Date?
    @State private var pausedTime: Date?
    @State private var remainingSeconds: Int
    @State private var shouldAnimate = true
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    let duration: Int
    let onFinish: (_ force: Bool) -> Void

    init(duration: Int, onFinish: @escaping (_ force: Bool) -> Void) {
        self.duration = duration
        self.onFinish = onFinish
        _remainingSeconds = State(initialValue: duration)
    }

    var body: some View {
        CircularTimerView(
            remainingSeconds: remainingSeconds,
            totalSeconds: duration,
            shouldAnimate: shouldAnimate
        )
        .navigationTitle(.timerScreenTitle)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                finishButton
            }
        }
        .onAppear {
            startTime = .now
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .onReceive(timer) { _ in
            guard let startTime else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= TimeInterval(duration) {
                return
            }
            updateRemainingSeconds()
            if remainingSeconds <= 0 {
                finishTimer(force: false)
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
            pausedTime = .now
        case (.background, .active), (.inactive, .active):
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= TimeInterval(duration) {
                remainingSeconds = 0
                shouldAnimate = false
                pausedTime = nil
                return
            }
            let newRemaining = max(0, duration - Int(elapsed))
            shouldAnimate = false
            remainingSeconds = newRemaining
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
            pausedTime.timeIntervalSince(startTime)
        } else {
            Date().timeIntervalSince(startTime)
        }
        if elapsed >= TimeInterval(duration) {
            remainingSeconds = 0
            return
        }
        let newRemaining = max(0, duration - Int(elapsed.rounded()))
        if newRemaining != remainingSeconds {
            remainingSeconds = newRemaining
        }
    }

    private func finishTimer(force: Bool) {
        timer.upstream.connect().cancel()
        if force {
            onFinish(true)
            dismiss()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onFinish(false)
                dismiss()
            }
        }
    }
}

private extension WorkoutRestTimerView {
    var finishButton: some View {
        Button {
            finishTimer(force: true)
        } label: {
            Image(systemName: "xmark")
        }
    }
}

#Preview("10 сек") {
    NavigationStack {
        WorkoutRestTimerView(duration: 10) { _ in }
    }
}
