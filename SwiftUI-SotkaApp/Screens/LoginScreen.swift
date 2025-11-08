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
    @State private var showLoginScreen = false
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
            ZStack {
                if showLoginScreen {
                    authView
                } else {
                    welcomeView
                }
            }
            .animation(.spring, value: showLoginScreen)
            .padding()
            .loadingOverlay(if: isLoading)
            .background(Color.swBackground)
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

    var welcomeView: some View {
        VStack(spacing: 32) {
            Image(.launcherLogo)
            VStack(spacing: 16) {
                Button(.loginScreenAuthorizeButtonTitle) {
                    showLoginScreen.toggle()
                }
                .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
                Text(.loginScreenRegistrationInfoText)
                    .font(.footnote.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.swMainText)
            }
        }
        .transition(.scale(2).combined(with: .opacity))
    }

    var authView: some View {
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
                backToWelcomeButton
            }
        }
    }

    @ViewBuilder
    var loginField: some View {
        SWTextField(
            placeholder: String(localized: .loginOrEmail),
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

    @ViewBuilder
    var backToWelcomeButton: some View {
        if showLoginScreen {
            Button {
                showLoginScreen.toggle()
            } label: {
                Image(systemName: "xmark")
            }
        }
    }

    func performLogin() {
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
            }
            isLoading = false
        }
    }

    func performRestorePassword() {
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
        .environment(StatusManager.preview)
        .environment(\.isNetworkConnected, true)
}

#Preview("Ошибка") {
    LoginScreen(client: MockLoginClient(result: .failure()))
        .environment(AuthHelperImp())
        .environment(StatusManager.preview)
        .environment(\.isNetworkConnected, true)
}
