import SwiftUI

struct AuthRequiredView: View {
    let checkAuthAction: () -> Void
    let state: AuthState

    var body: some View {
        VStack(spacing: 0) {
            Text(state.localizedTitle).bold()
            if state.isLoading {
                ProgressView("Watch.AuthRequired.Checking")
            } else {
                Button("Watch.AuthRequired.CheckButton", action: checkAuthAction)
                    .padding(.top, 20)
            }
        }
        .animation(.default, value: state)
    }
}

#Preview("Пример неудачной авторизации") {
    @Previewable @State var state = AuthState.idle
    AuthRequiredView(
        checkAuthAction: {
            print("Проверяем авторизацию")
            state = .loading
            Task {
                try? await Task.sleep(for: .seconds(2))
                state = .error
            }
        },
        state: state
    )
}
