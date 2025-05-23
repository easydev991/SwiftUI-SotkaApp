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
    @Query(sort: \Country.name, order: .forward) private var countries: [Country]
    @State private var selectedCountry = CountryResponse.defaultCountry.name
    @State private var selectedCity = CityResponse.defaultCity.name
    private var cities: [City] {
        guard let selected = countries.first(where: { $0.name == selectedCountry }) else {
            return []
        }
        return selected.cities.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let user {
                    Text("userId: \(user.id)")
                    Text("userName: \(String(describing: user.fullName))")
                    Text("userEmail: \(String(describing: user.email))")
                }
                if countries.isEmpty {
                    Text("Стран нет")
                } else {
                    NavigationLink {
                        ItemListScreen(
                            mode: .country,
                            allItems: countries.map(\.name),
                            selectedItem: selectedCountry,
                            didSelectItem: { selectedCountry = $0 },
                            didTapContactUs: { _ in print("todo")}
                        )
                    } label: {
                        Text("Список стран")
                    }
                }
                if cities.isEmpty {
                    Text("Городов нет")
                } else {
                    NavigationLink {
                        ItemListScreen(
                            mode: .city,
                            allItems: cities.map(\.name),
                            selectedItem: selectedCity,
                            didSelectItem: { selectedCity = $0 },
                            didTapContactUs: { _ in print("todo")}
                        )
                    } label: {
                        Text("Список городов")
                    }
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
        .modelContainer(PreviewModelContainer.make(with: .init(from: .preview)))
}
#endif
