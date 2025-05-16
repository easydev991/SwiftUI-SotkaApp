//
//  ProfileScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 10.05.2025.
//

import SwiftUI

struct ProfileScreen: View {
    @Environment(AuthHelperImp.self) private var authHelper
    @State private var showLogoutDialog = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Profile")
                    .navigationTitle("Profile")
                if let userInfo = authHelper.userInfo {
                    Text("User info: \(userInfo)")
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
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
                authHelper.triggerLogout()
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
