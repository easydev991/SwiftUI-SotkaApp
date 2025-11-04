import OSLog
import SwiftUI
import SWUtils

struct MoreScreen: View {
    @Environment(\.locale) private var locale
    @Environment(AppSettings.self) private var appSettings
    @Environment(InfopostsService.self) private var infopostsService
    @State private var aboutInfopost: Infopost?
    private let appId = "id6753644091"
    private let logger = Logger(subsystem: "SotkaApp", category: "MoreScreen")

    var body: some View {
        NavigationStack {
            @Bindable var settings = appSettings
            List {
                Section(.settings) {
                    appThemePicker
                    appLanguageButton
                    DisclosureGroup(.moreScreenWorkoutGroup) {
                        notificationToggle
                        if settings.workoutNotificationsEnabled {
                            makeNotificationTimePicker(
                                $settings.workoutNotificationTime
                            )
                        }
                        DisclosureGroup(.moreScreenRestGroup) {
                            makeTimerSoundToggle($settings.playTimerSound)
                            makeVibrateToggle($settings.vibrate)
                        }
                    }
                }
                Section(.aboutApp) {
                    rateAppButton
                    feedbackButton
                    officialSiteButton
                    shareAppButton
                    aboutProgramButton
                    appVersionText
                }
                Section(.otherApps) {
                    swParksButton
                }
                Section(.supportTheProject) {
                    workoutShopButton
                    githubButton
                }
            }
            .animation(.default, value: appSettings.workoutNotificationsEnabled)
            .navigationTitle(.more)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if aboutInfopost == nil {
                    aboutInfopost = infopostsService.loadAboutInfopost()
                }
            }
        }
    }

    @ViewBuilder
    private var appThemePicker: some View {
        @Bindable var settings = appSettings
        Picker(.appTheme, selection: $settings.appTheme) {
            ForEach(AppTheme.allCases) {
                Text($0.localizedTitle).tag($0)
            }
        }
        .accessibilityIdentifier("appThemeButton")
    }

    @ViewBuilder
    private var appLanguageButton: some View {
        @Bindable var settings = appSettings
        Picker(.appLanguage, selection: .constant(AppLanguage.makeCurrentValue(locale.identifier))) {
            ForEach(AppLanguage.allCases) {
                Text($0.localizedTitle).tag($0)
            }
        }
        .overlay { Rectangle().opacity(0.0001) }
        .contentShape(.rect)
        .onTapGesture {
            settings.showLanguageAlert.toggle()
        }
        .alert(.alertLanguage, isPresented: $settings.showLanguageAlert) {
            Button(.cancel, role: .cancel) {}
            Button(.goToSettings) {
                let settingsUrl = URL(string: UIApplication.openSettingsURLString)
                URLOpener.open(settingsUrl)
            }
        }
    }

    @ViewBuilder
    private var notificationToggle: some View {
        @Bindable var settings = appSettings
        Toggle(
            .workoutNotifications,
            isOn: .init(
                get: { appSettings.workoutNotificationsEnabled },
                set: {
                    appSettings.setWorkoutNotificationsEnabled($0)
                }
            )
        )
    }

    private func makeNotificationTimePicker(_ value: Binding<Date>) -> some View {
        DatePicker(
            .notificationTime,
            selection: value,
            displayedComponents: .hourAndMinute
        )
    }

    private func makeTimerSoundToggle(_ value: Binding<Bool>) -> some View {
        Toggle(.timerSoundToggle, isOn: value)
    }

    private func makeVibrateToggle(_ value: Binding<Bool>) -> some View {
        Toggle(.timerVibrateToggle, isOn: value)
    }

    private var feedbackButton: some View {
        Button(.sendFeedback) {
            appSettings.sendFeedback()
        }
        .accessibilityIdentifier("sendFeedbackButton")
    }

    @ViewBuilder
    private var rateAppButton: some View {
        if let appReviewLink = URL(string: "https://apps.apple.com/app/\(appId)?action=write-review") {
            Link(.rateTheApp, destination: appReviewLink)
                .accessibilityIdentifier("rateAppButton")
        }
    }

    @ViewBuilder
    private var officialSiteButton: some View {
        if let officialSiteLink = URL(string: "https://workout.su") {
            Link(.officialWebsite, destination: officialSiteLink)
                .accessibilityIdentifier("officialSiteButton")
        }
    }

    @ViewBuilder
    private var shareAppButton: some View {
        if let model = ShareAppURL(localeIdentifier: locale.identifier, appId: appId) {
            ShareLink(item: model.url) {
                Text(.shareTheApp)
            }
            .accessibilityIdentifier("shareAppButton")
        }
    }

    private var appVersionText: some View {
        HStack {
            Text(.appVersion)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(appSettings.appVersion)")
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var swParksButton: some View {
        if let githubLink = URL(string: "https://apps.apple.com/app/id6749501617") {
            Link(.streetWorkoutParks, destination: githubLink)
                .accessibilityIdentifier("swParksButton")
        }
    }

    @ViewBuilder
    private var workoutShopButton: some View {
        if let shopLink = URL(string: "https://workoutshop.ru/?utm_source=iOS&utm_medium=100&utm_campaign=NASTROIKI") {
            Link(.workoutShop, destination: shopLink)
                .accessibilityIdentifier("workoutShopButton")
        }
    }

    @ViewBuilder
    private var githubButton: some View {
        if let githubLink = URL(string: "https://github.com/easydev991/SwiftUI-SotkaApp") {
            Link(.gitHubPage, destination: githubLink)
                .accessibilityIdentifier("githubButton")
        }
    }

    @ViewBuilder
    private var aboutProgramButton: some View {
        if let aboutInfopost {
            NavigationLink(destination: InfopostDetailScreen(infopost: aboutInfopost)) {
                Text(.infopostAbout)
            }
            .accessibilityIdentifier("aboutProgramButton")
        }
    }
}

#if DEBUG
#Preview {
    MoreScreen()
        .environment(AppSettings())
        .environment(
            InfopostsService(
                language: "ru",
                infopostsClient: MockInfopostsClient(result: .success)
            )
        )
}
#endif
