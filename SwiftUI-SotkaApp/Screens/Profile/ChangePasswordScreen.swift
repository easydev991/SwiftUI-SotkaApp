import SWDesignSystem
import SwiftUI
import SWUtils

/// Экран для смены пароля
struct ChangePasswordScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthHelperImp.self) private var authHelper
    @Environment(\.isNetworkConnected) private var isNetworkConnected
    @State private var model = PassworModel()
    @State private var isLoading = false
    @State private var isChangeSuccessful = false
    @State private var changePasswordTask: Task<Void, Never>?
    @FocusState private var focus: FocusableField?
    private var client: ProfileClient { SWClient(with: authHelper) }
    let userName: String

    var body: some View {
        VStack(spacing: 22) {
            SectionView(headerWithPadding: "Current password", mode: .regular) {
                passwordField
            }
            SectionView(headerWithPadding: "New password", mode: .regular) {
                newPasswordField
            }
            SectionView(headerWithPadding: "Password confirmation", mode: .regular) {
                newRepeatedField
            }
            Spacer()
            changePasswordButton
        }
        .padding()
        .loadingOverlay(if: isLoading)
        .background(Color.swBackground)
        .onDisappear { changePasswordTask?.cancel() }
        .navigationTitle("Change password")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ChangePasswordScreen {
    struct PassworModel {
        struct NewPassword {
            var text = ""
            var isError: Bool { !errorMessage.isEmpty }
            var errorMessage: String {
                text.trueCount < Constants.minPasswordSize
                    && !text.isEmpty
                    ? NSLocalizedString("Error.PasswordMinLenght", comment: "")
                    : ""
            }
        }

        struct NewRepeatedPassword {
            var text = ""
            /// Сравнивает с новым паролем и возвращает ошибку, если они не совпадает
            func check(with new: String) -> String {
                guard !text.isEmpty else { return "" }
                return text == new
                ? ""
                : NSLocalizedString("Error.PasswordNotMatch", comment: "")
            }
        }

        var current = ""
        var new = NewPassword()
        var newRepeated = NewRepeatedPassword()

        var isReady: Bool {
            [current, new.text].allSatisfy {
                $0.trueCount >= Constants.minPasswordSize
            }
                && new.text == newRepeated.text
        }
    }

    enum FocusableField: Hashable {
        case current, new, newRepeated
    }

    var canChangePassword: Bool {
        model.isReady && !isChangeSuccessful
    }

    @ViewBuilder
    var passwordField: some View {
        let localizedPlaceholder = NSLocalizedString("Placeholder.EnterPassword", comment: "")
        SWTextField(
            placeholder: localizedPlaceholder,
            text: $model.current,
            isSecure: true,
            isFocused: focus == .current
        )
        .focused($focus, equals: .current)
        .task {
            guard focus == nil else { return }
            try? await Task.sleep(nanoseconds: 500_000_000)
            focus = .current
        }
    }

    @ViewBuilder
    var newPasswordField: some View {
        let localizedPlaceholder = NSLocalizedString("Placeholder.EnterNewPassword", comment: "")
        SWTextField(
            placeholder: localizedPlaceholder,
            text: $model.new.text,
            isSecure: true,
            isFocused: focus == .new,
            errorState: model.new.isError
                ? .message(model.new.errorMessage)
                : nil
        )
        .focused($focus, equals: .new)
    }

    @ViewBuilder
    var newRepeatedField: some View {
        let localizedPlaceholder = NSLocalizedString("Placeholder.RepeatNewPassword", comment: "")
        let errorMessage = model.newRepeated.check(with: model.new.text)
        SWTextField(
            placeholder: localizedPlaceholder,
            text: $model.newRepeated.text,
            isSecure: true,
            isFocused: focus == .newRepeated,
            errorState: errorMessage.isEmpty ? nil : .message(errorMessage)
        )
        .focused($focus, equals: .newRepeated)
    }

    var changePasswordButton: some View {
        Button("Save changes", action: changePasswordAction)
            .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
            .disabled(!canChangePassword)
            .alert("Alert.PasswordChanged", isPresented: $isChangeSuccessful) {
                Button("Ok") { dismiss() }
            }
    }

    func changePasswordAction() {
        guard !isLoading else { return }
        guard !SWAlert.shared.presentNoConnection(isNetworkConnected) else { return }
        focus = nil
        isLoading = true
        changePasswordTask = Task {
            do {
                try await client.changePassword(
                    current: model.current,
                    new: model.new.text
                )
                try Task.checkCancellation()
                authHelper.updateAuthData(login: userName, newPassword: model.new.text)
                isChangeSuccessful = true
            } catch {
                SWAlert.shared.presentDefaultUIKit(
                    title: NSLocalizedString("Error", comment: ""),
                    message: error.localizedDescription
                )
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordScreen(userName: "demoUser")
            .environment(AuthHelperImp())
            .environment(\.isNetworkConnected, true)
    }
}
