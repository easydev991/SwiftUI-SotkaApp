import SWDesignSystem
import SwiftData
import SwiftUI
import SWUtils

struct EditProfileScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthHelperImp.self) private var authHelper
    @Environment(\.isNetworkConnected) private var isNetworkConnected
    @Environment(\.isIPad) private var isIPad
    @Query(sort: \Country.name, order: .forward) private var countries: [Country]
    private var cities: [City] {
        guard let selected = countries.first(where: { $0.name == userForm.country.name })
        else { return [] }
        return selected.cities.sorted { $0.name < $1.name }
    }

    @State private var isLoading = false
    @State private var oldUserForm: MainUserForm
    @State private var userForm: MainUserForm
    @State private var showImagePickerDialog = false
    @State private var newAvatarImageModel: AvatarModel?
    @State private var pickerSourceType: UIImagePickerController.SourceType?
    @State private var editUserTask: Task<Void, Never>?
    @FocusState private var focus: FocusableField?
    private let user: User
    private let client: ProfileClient

    init(user: User, client: ProfileClient) {
        self.user = user
        self._oldUserForm = .init(initialValue: .init(user))
        self._userForm = .init(initialValue: .init(user))
        self.client = client
    }

    var body: some View {
        VStack(spacing: 12) {
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
                .padding()
            }
            saveChangesButton
                .padding([.horizontal, .bottom])
        }
        .loadingOverlay(if: isLoading)
        .background(Color.swBackground)
        .onAppear(perform: prepareUserForm)
        .onDisappear { editUserTask?.cancel() }
        .navigationTitle(.editProfile)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension EditProfileScreen {
    enum FocusableField: Hashable {
        case login, email, fullName
    }

    struct AvatarModel: Equatable {
        let id = UUID().uuidString
        let uiImage: UIImage
    }

    var horizontalView: some View {
        HStack(alignment: .top, spacing: 32) {
            VStack(spacing: 12) {
                avatarPicker
            }
            VStack(spacing: 4) {
                VStack(spacing: 12) {
                    loginField
                    emailField
                    nameField
                    changePasswordButton
                }
                genderPicker
                birthdayPicker
                countryPicker
                cityPicker
            }
        }
    }

    var verticalView: some View {
        VStack(spacing: 12) {
            avatarPicker
                .padding(.bottom, 8)
            loginField
            emailField
            nameField
            changePasswordButton
            VStack(spacing: 4) {
                genderPicker
                birthdayPicker
                countryPicker
                cityPicker
            }
        }
    }

    var avatarPicker: some View {
        VStack(spacing: 20) {
            if let model = newAvatarImageModel {
                Image(uiImage: model.uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(.rect(cornerRadius: 12))
                    .transition(.scale.combined(with: .slide).combined(with: .opacity))
                    .id(model.id)
            } else {
                CachedImage(url: user.avatarUrl, mode: .profileAvatar)
                    .transition(.scale.combined(with: .slide).combined(with: .opacity))
            }
            Button(.changeProfilePhoto) { showImagePickerDialog.toggle() }
                .buttonStyle(SWButtonStyle(mode: .tinted, size: .large))
                .confirmationDialog(
                    "",
                    isPresented: $showImagePickerDialog,
                    titleVisibility: .hidden
                ) {
                    Button(.takeAPhoto) {
                        pickerSourceType = .camera
                    }
                    Button(.pickFromGallery) {
                        pickerSourceType = .photoLibrary
                    }
                }
        }
        .animation(.default, value: newAvatarImageModel)
        .fullScreenCover(item: $pickerSourceType) { sourceType in
            SWImagePicker(sourceType: sourceType) {
                newAvatarImageModel = .init(uiImage: $0)
                userForm.image = $0.toMediaFile()
            }
            .ignoresSafeArea()
        }
    }

    var loginField: some View {
        SWTextField(
            placeholder: userForm.placeholder(.userName),
            text: $userForm.userName,
            isFocused: focus == .login
        )
        .focused($focus, equals: .login)
    }

    var emailField: some View {
        SWTextField(
            placeholder: userForm.placeholder(.email),
            text: $userForm.email,
            isFocused: focus == .email
        )
        .focused($focus, equals: .email)
    }

    var nameField: some View {
        SWTextField(
            placeholder: userForm.placeholder(.fullname),
            text: $userForm.fullName,
            isFocused: focus == .fullName
        )
        .focused($focus, equals: .fullName)
    }

    @ViewBuilder
    var changePasswordButton: some View {
        if let userName = user.userName {
            NavigationLink(destination: ChangePasswordScreen(userName: userName)) {
                let localizedString = String(localized: .changePassword)
                ListRowView(leadingContent: .iconWithText(.key, localizedString), trailingContent: .chevron)
            }
        }
    }

    var genderPicker: some View {
        Menu {
            Picker(.placeholderGender, selection: $userForm.genderCode) {
                ForEach([Gender.male, Gender.female], id: \.code) {
                    Text($0.affiliation)
                }
            }
        } label: {
            ListRowView(
                leadingContent: .iconWithText(
                    .personQuestion,
                    userForm.placeholder(.gender)
                ),
                trailingContent: .textWithChevron(userForm.genderString)
            )
        }
    }

    var birthdayPicker: some View {
        HStack(spacing: 12) {
            ListRowView.LeadingContent.makeIconView(with: Icons.Regular.calendar)
            DatePicker(
                userForm.placeholder(.birthDate),
                selection: $userForm.birthDate,
                in: ...Constants.minUserAge,
                displayedComponents: .date
            )
        }
        .padding(.vertical, 16)
    }

    var countryPicker: some View {
        NavigationLink {
            ItemListScreen(
                mode: .country,
                allItems: countries.map(\.name),
                selectedItem: userForm.country.name,
                didSelectItem: { selectCountry(name: $0) },
                didTapContactUs: sendFeedback
            )
        } label: {
            ListRowView(
                leadingContent: .iconWithText(
                    .globe,
                    userForm.placeholder(.country)
                ),
                trailingContent: .textWithChevron(userForm.country.name)
            )
        }
        .padding(.bottom, 6)
    }

    var cityPicker: some View {
        NavigationLink {
            ItemListScreen(
                mode: .city,
                allItems: cities.map(\.name),
                selectedItem: userForm.city.name,
                didSelectItem: { selectCity(name: $0) },
                didTapContactUs: sendFeedback
            )
        } label: {
            ListRowView(
                leadingContent: .iconWithText(
                    .signPost,
                    userForm.placeholder(.city)
                ),
                trailingContent: .textWithChevron(userForm.city.name)
            )
        }
    }

    func prepareUserForm() {
        guard oldUserForm.shouldUpdateOnAppear else { return }
        let userCountry = countries.first(where: { $0.id == oldUserForm.country.id })
        if let userCountry {
            let cities: [CityResponse] = userCountry.cities.map {
                .init(id: $0.id, name: $0.name, lat: $0.lat, lon: $0.lon)
            }
            oldUserForm.country = .init(
                cities: cities,
                id: userCountry.id,
                name: userCountry.name
            )
        } else {
            oldUserForm.country = .defaultCountry
        }
        if let userCountry, let userCity = userCountry.cities.first(where: { $0.id == oldUserForm.city.id }) {
            oldUserForm.city = .init(
                id: userCity.id,
                name: userCity.name,
                lat: userCity.lat,
                lon: userCity.lon
            )
        } else {
            oldUserForm.city = .defaultCity
        }
        userForm = oldUserForm
    }

    func selectCountry(name countryName: String) {
        guard let newCountry = countries.first(where: { $0.name == countryName }) else {
            return
        }
        userForm.country = .init(
            cities: newCountry.cities.map { .init(id: $0.id, name: $0.name, lat: $0.lat, lon: $0.lon) },
            id: newCountry.id,
            name: newCountry.name
        )
        if !newCountry.cities.contains(where: { $0.id == userForm.city.id }),
           let firstCity = newCountry.cities.first {
            userForm.city = .init(
                id: firstCity.id,
                name: firstCity.name,
                lat: firstCity.lat,
                lon: firstCity.lon
            )
        }
    }

    func selectCity(name cityName: String) {
        let newCity: CityResponse? = cities.map {
            .init(
                id: $0.id,
                name: $0.name,
                lat: $0.lat,
                lon: $0.lon
            )
        }.first(where: { $0.name == cityName })
        guard let newCity else { return }
        userForm.city = newCity
    }

    var saveChangesButton: some View {
        Button(.saveChanges, action: saveChangesAction)
            .buttonStyle(SWButtonStyle(mode: .filled, size: .large))
            .disabled(!userForm.isReadyToSave(comparedTo: oldUserForm))
    }

    func sendFeedback(mode: ItemListScreen.Mode) {
        let (subject, body) = switch mode {
        case .city: (LocationFeedback.city.subject, LocationFeedback.city.body)
        case .country: (LocationFeedback.country.subject, LocationFeedback.country.body)
        }
        FeedbackSender.sendFeedback(
            subject: subject,
            messageBody: body,
            recipients: Constants.feedbackRecipients
        )
    }

    func saveChangesAction() {
        guard !SWAlert.shared.presentNoConnection(isNetworkConnected) else { return }
        isLoading = true
        editUserTask = Task {
            do {
                let response = try await client.editUser(user.id, model: userForm)
                try Task.checkCancellation()
                user.userName = response.name
                user.fullName = response.fullname
                user.email = response.email
                user.imageStringURL = response.image
                user.cityId = response.cityId
                user.countryId = response.countryId
                user.genderCode = response.gender
                user.birthDateIsoString = response.birthDate
                authHelper.updateAuthData(login: userForm.userName)
                // Без ожидания не загружается аватарка на экране профиля
                try await Task.sleep(for: .seconds(0.5))
                dismiss()
            } catch {
                isLoading = false
                SWAlert.shared.presentDefaultUIKit(error)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        EditProfileScreen(
            user: .init(from: .preview),
            client: MockProfileClient(result: .success)
        )
        .environment(AuthHelperImp())
        .environment(\.isNetworkConnected, true)
    }
}
#endif
