//
//  LoginScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 15.05.2025.
//

import SwiftUI
import SWKeychain
import SWUtils
import SwiftData

struct LoginScreen: View {
    @Environment(AuthHelperImp.self) private var authHelper
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
    private var client: SWClient { SWClient(with: authHelper) }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    loginField
                    passwordField
                }
                .textFieldStyle(.roundedBorder)
                Spacer()
                VStack(spacing: 12) {
                    loginButton
                    forgotPasswordButton
                }
            }
            .loadingOverlay(isLoading)
            .padding()
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
    
    var loginField: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Login or emal", text: $credentials.login)
                .focused($focus, equals: .username)
                .task {
                    guard focus == nil else { return }
                    try? await Task.sleep(for: .seconds(0.5))
                    focus = .username
                }
            makeErrorView(for: resetErrorMessage)
        }
    }
    
    var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            SecureField("Password", text: $credentials.password)
                .focused($focus, equals: .password)
            makeErrorView(for: authErrorMessage)
        }
    }
    
    var loginButton: some View {
        Button("Log in", action: performLogin)
            .buttonStyle(.borderedProminent)
            .disabled(!canLogIn)
    }
    
    var forgotPasswordButton: some View {
        Button("Restore password", action: performRestorePassword)
            .buttonStyle(.bordered)
    }
    
    func makeErrorView(for message: String) -> some View {
        ZStack {
            if !message.isEmpty {
                Text(message)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
                    .font(.footnote)
            }
        }
        .animation(.default, value: message)
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

#Preview {
    LoginScreen()
        .environment(AuthHelperImp())
}
