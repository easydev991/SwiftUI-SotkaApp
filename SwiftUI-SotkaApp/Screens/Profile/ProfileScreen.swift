//
//  ProfileScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 10.05.2025.
//

import SwiftUI
import SwiftData
import SWDesignSystem

struct ProfileScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthHelperImp.self) private var authHelper
    @State private var showLogoutDialog = false
    @Query private var users: [User]
    private var user: User? { users.first }
    @Query private var countries: [Country]
    private var userAddress: String {
        guard let user,
              let countryID = user.countryId,
              let cityID = user.cityId,
              let country = countries.first(where: { $0.id == String(countryID) })
        else {
            return ""
        }
        if let city = country.cities.first(where: { $0.id == String(cityID) }) {
            return country.name + ", " + city.name
        } else {
            return country.name
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let user {
                        ProfileView(
                            imageURL: user.avatarUrl,
                            login: user.userName ?? "",
                            genderWithAge: user.genderWithAge,
                            countryAndCity: userAddress
                        )
                        .id(user.avatarUrl)
                        .padding(24)
                        makeEditProfileButton(for: user)
                        logoutButton
                    }
                }
                .padding(.horizontal)
            }
            .background(Color.swBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension ProfileScreen {
    func makeEditProfileButton(for user: User) -> some View {
        NavigationLink(
            "Edit profile",
            destination: EditProfileScreen(user: user)
        )
        .buttonStyle(SWButtonStyle(icon: .pencil, mode: .tinted, size: .large))
        .padding(.bottom, 24)
    }
    
    var logoutButton: some View {
        Button("Log out") {
            showLogoutDialog = true
        }
        .foregroundStyle(Color.swSmallElements)
        .padding(.top, 36)
        .padding(.bottom, 20)
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
        .modelContainer(PreviewModelContainer.make(with: .init(from: .preview)))
}
#endif
