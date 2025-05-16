//
//  ProfileScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 10.05.2025.
//

import SwiftUI
import SwiftData

struct ProfileScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthHelperImp.self) private var authHelper
    @Query private var users: [User]
    private var user: User? { users.first }
    @State private var showLogoutDialog = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let user {
                    Text("userId: \(user.id)")
                    Text("userName: \(user.fullName)")
                    Text("userEmail: \(user.email)")
                }
                Spacer()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    logoutButton
                }
            }
        }
    }
    
    private var logoutButton: some View {
        Button("Log out") {
            showLogoutDialog = true
        }
        .confirmationDialog(
            "Alert.logout",
            isPresented: $showLogoutDialog,
            titleVisibility: .visible
        ) {
            Button("Log out", role: .destructive) {
                do {
                    authHelper.triggerLogout()
                    try modelContext.delete(model: User.self)
                } catch {
                    fatalError("Не удалось удалить пользователя: \(error.localizedDescription)")
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ProfileScreen()
        .environment(AuthHelperImp())
}
#endif
