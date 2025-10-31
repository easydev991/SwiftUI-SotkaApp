import SWDesignSystem
import SwiftData
import SwiftUI

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
                        makeProfileView(for: user)
                        makeEditProfileButton(for: user)
                        VStack(spacing: 12) {
                            makeJournalButton(for: user)
                            makeProgressButton(for: user)
                            makeCustomExercisesButton(for: user)
                        }
                        logoutButton
                    }
                }
                .padding(.horizontal)
            }
            .background(Color.swBackground)
            .navigationTitle(.profile)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension ProfileScreen {
    func makeProfileView(for user: User) -> some View {
        ProfileView(
            imageURL: user.avatarUrl,
            login: user.userName ?? "",
            genderWithAge: user.genderWithAge,
            countryAndCity: userAddress
        )
        .id(user.avatarUrl)
        .padding(24)
    }

    func makeEditProfileButton(for user: User) -> some View {
        NavigationLink(.editProfile) {
            EditProfileScreen(user: user)
        }
        .buttonStyle(SWButtonStyle(icon: .pencil, mode: .tinted, size: .large))
        .padding(.bottom, 24)
    }

    func makeJournalButton(for user: User) -> some View {
        NavigationLink(destination: JournalScreen(user: user)) {
            let localizedString = String(localized: .journal)
            FormRowView(
                title: localizedString,
                trailingContent: .textWithChevron("")
            )
        }
    }

    func makeProgressButton(for user: User) -> some View {
        NavigationLink(destination: ProgressScreen(user: user)) {
            let localizedString = String(localized: .progress)
            FormRowView(
                title: localizedString,
                trailingContent: .textWithChevron("")
            )
        }
    }

    func makeCustomExercisesButton(for user: User) -> some View {
        NavigationLink(destination: CustomExercisesScreen()) {
            let localizedString = String(localized: .customExercises)
            FormRowView(
                title: localizedString,
                trailingContent: .textWithChevron(user.customExerciseCountText)
            )
        }
    }

    var logoutButton: some View {
        Button(.logOut) {
            showLogoutDialog = true
        }
        .foregroundStyle(Color.swSmallElements)
        .padding(.top, 36)
        .padding(.bottom, 20)
        .confirmationDialog(
            .alertLogout,
            isPresented: $showLogoutDialog,
            titleVisibility: .visible
        ) {
            Button(.logOut, role: .destructive) {
                authHelper.triggerLogout()
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
