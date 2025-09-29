import SWDesignSystem
import SwiftData
import SwiftUI
import SWKeychain
import SWUtils

struct LoginScreen: View {
    @Environment(AuthHelperImp.self) private var authHelper
    @Environment(StatusManager.self) private var statusManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isNetworkConnected) private var isNetworkConnected
    @State private var credentials = LoginCredentials()
    @FocusState private var focus: FocusableField?
    @State private var isLoading = false
    /// Текст ошибки при восстановлении пароля
    @State private var resetErrorMessage = ""
    /// Текст ошибки при авторизации
    @State private var authErrorMessage = ""
    @State private var loginTask: Task<Void, Never>?
    @State private var restorePasswordTask: Task<Void, Never>?
    let client: LoginClient & StatusClient

    var body: some View {
        NavigationStack {
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
            .padding()
            .loadingOverlay(if: isLoading)
            .background(Color.swBackground)
            .navigationTitle("Authorization")
            .onChange(of: credentials) { _, _ in clearErrorMessages() }
            .onChange(of: isLoading) { _, newValue in
                if newValue { focus = nil }
            }
            .onDisappear {
                [loginTask, restorePasswordTask].forEach { $0?.cancel() }
            }
        }
    }
}

private extension LoginScreen {
    enum FocusableField: Hashable {
        case username, password
    }

    var isError: Bool {
        !authErrorMessage.isEmpty || !resetErrorMessage.isEmpty
    }

    var canLogIn: Bool {
        credentials.canLogIn(isError: isError)
    }

    @ViewBuilder
    var loginField: some View {
        let localizedPlaceholder = NSLocalizedString("Login or email", comment: "")
        SWTextField(
            placeholder: localizedPlaceholder,
            text: $credentials.login,
            isFocused: focus == .username,
            errorState: isError ? .message(resetErrorMessage) : nil
        )
        .focused($focus, equals: .username)
        .task {
            guard focus == nil else { return }
            try? await Task.sleep(for: .seconds(0.5))
            focus = .username
        }
        .accessibilityIdentifier("loginField")
    }

    @ViewBuilder
    var passwordField: some View {
        let localizedPlaceholder = NSLocalizedString("Password", comment: "")
        SWTextField(
            placeholder: localizedPlaceholder,
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
        Button("Log in", action: performLogin)
            .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
            .disabled(!canLogIn)
            .accessibilityIdentifier("loginButton")
    }

    var forgotPasswordButton: some View {
        Button("Restore password", action: performRestorePassword)
            .tint(.swMainText)
    }

    func performLogin() {
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
                await statusManager.getStatus(client: client, context: modelContext)
            } catch ClientError.noConnection {
                SWAlert.shared.presentNoConnection(true)
            } catch {
                authErrorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func performRestorePassword() {
        guard credentials.canRestorePassword else {
            let localizedString = NSLocalizedString("Alert.restorePassword", comment: "")
            SWAlert.shared.presentDefaultUIKit(
                message: localizedString,
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
                    title: NSLocalizedString("Done", comment: ""),
                    message: NSLocalizedString("Alert.resetSuccessful", comment: "")
                )
            } catch ClientError.noConnection {
                SWAlert.shared.presentNoConnection(true)
            } catch {
                resetErrorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func clearErrorMessages() {
        authErrorMessage = ""
        resetErrorMessage = ""
    }
}

#Preview("Успех") {
    LoginScreen(client: MockLoginClient(result: .success))
        .environment(AuthHelperImp())
        .environment(\.isNetworkConnected, true)
}

#Preview("Ошибка") {
    LoginScreen(client: MockLoginClient(result: .failure()))
        .environment(AuthHelperImp())
        .environment(\.isNetworkConnected, true)
}
