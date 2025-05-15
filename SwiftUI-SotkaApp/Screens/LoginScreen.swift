//
//  LoginScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 15.05.2025.
//

import SwiftUI

struct LoginScreen: View {
    @State private var credentials = LoginCredentials()
    @FocusState private var focus: FocusableField?
    @State private var isLoading = false
    /// Текст ошибки при восстановлении пароля
    @State private var resetErrorMessage = ""
    /// Текст ошибки при авторизации
    @State private var authErrorMessage = ""
    @State private var loginTask: Task<Void, Never>?
    @State private var restorePasswordTask: Task<Void, Never>?
    
    var body: some View {
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
        .onDisappear {
            [loginTask, restorePasswordTask].forEach { $0?.cancel() }
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
            TextField("Password", text: $credentials.password)
                .focused($focus, equals: .password)
            makeErrorView(for: authErrorMessage)
        }
    }
    
    var loginButton: some View {
        Button("Log in") {
            focus = nil
            performLogin()
        }
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
            print("Авторизуемся")
            try? await Task.sleep(for: .seconds(2))
            isLoading = false
            authErrorMessage = "Demo error"
        }
    }
    
    func performRestorePassword() {
        clearErrorMessages()
        isLoading = true
        restorePasswordTask = Task {
            print("Восстанавливаем пароль")
            try? await Task.sleep(for: .seconds(4))
            isLoading = false
            resetErrorMessage = "Demo error"
        }
    }
    
    func clearErrorMessages() {
        authErrorMessage = ""
        resetErrorMessage = ""
    }
}

#Preview {
    LoginScreen()
}
