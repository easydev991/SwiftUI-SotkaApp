import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct ProfileScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthHelperImp.self) private var authHelper
    @Environment(\.isNetworkConnected) private var isNetworkConnected
    @Environment(\.isIPad) private var isIPad
    @State private var showLogoutDialog = false
    private var client: ProfileClient { SWClient(with: authHelper) }
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
                Group {
                    if isIPad {
                        verticalView
                    } else {
                        ViewThatFits {
                            horizontalView
                            verticalView
                        }
                    }
                }
                .padding(.horizontal)
            }
            .refreshable { await refreshProfile() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    logoutButton
                }
            }
            .background(Color.swBackground)
            .navigationTitle(.profile)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension ProfileScreen {
    var horizontalView: some View {
        HStack(spacing: 16) {
            if let user {
                VStack(spacing: 12) {
                    makeProfileView(for: user)
                    makeEditProfileButton(for: user)
                }
                VStack(spacing: 12) {
                    makeJournalButton(for: user)
                    makeProgressButton(for: user)
                    makeCustomExercisesButton(for: user)
                }
            }
        }
    }

    var verticalView: some View {
        VStack(spacing: 0) {
            if let user {
                makeProfileView(for: user)
                    .padding(24)
                makeEditProfileButton(for: user)
                    .padding(.bottom, 24)
                VStack(spacing: 12) {
                    makeJournalButton(for: user)
                    makeProgressButton(for: user)
                    makeCustomExercisesButton(for: user)
                }
            }
        }
    }

    func makeProfileView(for user: User) -> some View {
        ProfileView(
            imageURL: user.avatarUrl,
            login: user.userName ?? "",
            genderWithAge: user.genderWithAge,
            countryAndCity: userAddress
        )
        .id(user.avatarUrl)
    }

    func makeEditProfileButton(for user: User) -> some View {
        NavigationLink(.editProfile) {
            EditProfileScreen(user: user, client: client)
        }
        .buttonStyle(SWButtonStyle(icon: .pencil, mode: .tinted, size: .large))
    }

    func makeJournalButton(for user: User) -> some View {
        NavigationLink(destination: JournalScreen(user: user)) {
            let localizedString = String(localized: .journal)
            FormRowView(
                title: localizedString,
                trailingContent: .textWithChevron("")
            )
        }
        .accessibilityIdentifier("ProfileJournalButton")
    }

    func makeProgressButton(for user: User) -> some View {
        NavigationLink(destination: ProgressScreen(user: user)) {
            let localizedString = String(localized: .progress)
            FormRowView(
                title: localizedString,
                trailingContent: .textWithChevron("")
            )
        }
        .accessibilityIdentifier("ProfileProgressButton")
    }

    func makeCustomExercisesButton(for user: User) -> some View {
        NavigationLink(destination: CustomExercisesScreen()) {
            let localizedString = String(localized: .customExercises)
            FormRowView(
                title: localizedString,
                trailingContent: .textWithChevron(user.customExerciseCountText)
            )
        }
        .accessibilityIdentifier("ProfileExercisesButton")
    }

    var logoutButton: some View {
        Button(.logOut) {
            showLogoutDialog = true
        }
        .foregroundStyle(Color.swSmallElements)
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

    func refreshProfile() async {
        guard let user else { return }
        guard !SWAlert.shared.presentNoConnection(isNetworkConnected) else { return }
        do {
            let response = try await client.getUserByID(user.id)
            user.userName = response.name
            user.fullName = response.fullname
            user.email = response.email
            user.imageStringURL = response.image
            user.cityId = response.cityId
            user.countryId = response.countryId
            user.genderCode = response.gender
            user.birthDateIsoString = response.birthDateIsoString
        } catch {
            SWAlert.shared.presentDefaultUIKit(error)
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
