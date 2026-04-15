import SWDesignSystem
import SwiftUI
import SWKeychain
import SWUtils

struct OnlineLoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthHelperImp.self) private var authHelper
    @Environment(\.analyticsService) private var analytics
    @Environment(\.isNetworkConnected) private var isNetworkConnected
    @State private var credentials = LoginCredentials()
    @State private var isLoading = false
    @State private var resetErrorMessage = ""
    @State private var authErrorMessage = ""
    @State private var loginTask: Task<Void, Never>?
    @State private var restorePasswordTask: Task<Void, Never>?
    @FocusState private var focus: FocusableField?
    let client: LoginClient & StatusClient
    let closeAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                loginField
                passwordField
            }
            Spacer()
            VStack(spacing: 12) {
                loginButton
                forgotPasswordButton
            }
        }
        .navigationTitle(.authorization)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseButton(mode: .xmark, action: closeAction)
            }
        }
        .loadingOverlay(if: isLoading)
        .onChange(of: credentials) { _, _ in clearErrorMessages() }
        .onChange(of: isLoading) { _, newValue in
            if newValue { focus = nil }
        }
        .onDisappear {
            [loginTask, restorePasswordTask].forEach { $0?.cancel() }
        }
        .trackScreen(.onlineLogin)
    }
}

private extension OnlineLoginView {
    enum FocusableField: Hashable {
        case username, password
    }

    var isError: Bool {
        !authErrorMessage.isEmpty || !resetErrorMessage.isEmpty
    }

    var canLogIn: Bool {
        credentials.canLogIn(isError: isError)
    }

    var loginField: some View {
        SWTextField(
            placeholder: String(localized: .loginOrEmail),
            text: $credentials.login,
            isFocused: focus == .username,
            errorState: isError ? .message(resetErrorMessage) : nil
        )
        .focused($focus, equals: .username)
        .task {
            try? await Task.sleep(for: .seconds(1))
            guard focus == nil else { return }
            focus = .username
        }
        .accessibilityIdentifier("loginField")
    }

    var passwordField: some View {
        SWTextField(
            placeholder: String(localized: .password),
            text: $credentials.password,
            isSecure: true,
            isFocused: focus == .password,
            errorState: !authErrorMessage.isEmpty ? .message(authErrorMessage) : nil
        )
        .focused($focus, equals: .password)
        .onSubmit {
            if credentials.isReady {
                performLogin()
            }
        }
        .accessibilityIdentifier("passwordField")
    }

    var loginButton: some View {
        Button(.logIn, action: performLogin)
            .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
            .disabled(!canLogIn)
            .accessibilityIdentifier("loginButton")
    }

    var forgotPasswordButton: some View {
        Button(.restorePassword, action: performRestorePassword)
            .tint(.swMainText)
    }

    func performLogin() {
        analytics.log(.userAction(action: .login))
        guard !isLoading else { return }
        isLoading = true
        loginTask = Task {
            do {
                let authData = AuthData(
                    login: credentials.login,
                    password: credentials.password
                )
                let userId = try await client.logIn(with: authData.token)
                authHelper.saveAuthData(authData)
                let userInfo = try await client.getUserByID(userId)
                authHelper.didAuthorize()
                let user = User(from: userInfo)
                modelContext.insert(user)
                try modelContext.save()
            } catch ClientError.noConnection {
                SWAlert.shared.presentNoConnection(true)
            } catch {
                authErrorMessage = error.localizedDescription
                analytics.log(.appError(kind: .loginFailed, error: error))
            }
            isLoading = false
        }
    }

    func performRestorePassword() {
        analytics.log(.userAction(action: .resetPassword))
        guard credentials.canRestorePassword else {
            SWAlert.shared.presentDefaultUIKit(
                message: String(localized: .alertRestorePassword),
                completion: { focus = .username }
            )
            return
        }
        guard !SWAlert.shared.presentNoConnection(isNetworkConnected) else { return }
        clearErrorMessages()
        isLoading = true
        restorePasswordTask = Task {
            do {
                try await client.resetPassword(for: credentials.login)
                SWAlert.shared.presentDefaultUIKit(
                    title: String(localized: .done),
                    message: String(localized: .alertResetSuccessful)
                )
            } catch ClientError.noConnection {
                SWAlert.shared.presentNoConnection(true)
            } catch {
                resetErrorMessage = error.localizedDescription
                analytics.log(.appError(kind: .passwordResetFailed, error: error))
            }
            isLoading = false
        }
    }

    func clearErrorMessages() {
        authErrorMessage = ""
        resetErrorMessage = ""
    }
}

#if DEBUG
#Preview("Успех") {
    NavigationStack {
        OnlineLoginView(
            client: MockLoginClient(result: .success),
            closeAction: { print("нажали крестик") }
        )
        .padding()
        .environment(AuthHelperImp())
        .environment(\.isNetworkConnected, true)
    }
}

#Preview("Ошибка") {
    NavigationStack {
        OnlineLoginView(
            client: MockLoginClient(result: .failure()),
            closeAction: { print("нажали крестик") }
        )
        .padding()
        .environment(AuthHelperImp())
        .environment(\.isNetworkConnected, true)
    }
}
#endif
