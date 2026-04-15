import OSLog
import SwiftData
import SwiftUI
import SWUtils

struct MoreScreen: View {
    @Environment(\.locale) private var locale
    @Environment(\.currentDay) private var currentDay
    @Environment(AppSettings.self) private var appSettings
    @Environment(StatusManager.self) private var statusManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analyticsService) private var analytics
    @Environment(AuthHelperImp.self) private var authHelper
    @AppStorage(Key.isWorkoutGroupExpanded.rawValue) private var isWorkoutGroupExpanded = true
    @AppStorage(Key.isWorkoutRestGroupExpanded.rawValue) private var isWorkoutRestGroupExpanded = true
    let user: User
    @State private var aboutInfopost: Infopost?
    @State private var showResetDialog = false
    @State private var showLogoutDialog = false
    private var isOfflineUser: Bool {
        user.isOfflineOnly
    }

    private var client: ProfileClient {
        SWClient(with: authHelper)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(.profile) {
                    if !isOfflineUser {
                        NavigationLink {
                            EditProfileScreen(user: user, client: client)
                        } label: {
                            Text(.editProfile)
                        }
                    }
                    logoutButton
                }
                Section(.settings) {
                    appThemeAndIconButton
                    appLanguageButton
                    #if DEBUG
                    debugCurrentDayPicker
                    #endif
                    workoutSettingsGroup
                    if !isOfflineUser {
                        syncJournalButton
                    }
                }
                if currentDay > 1 {
                    Section(.moreScreenResetProgramSection) {
                        resetProgramButton
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
                    daysCounterButton
                }
                Section(.supportTheProject) {
                    githubButton
                }
            }
            .animation(.default, value: appSettings.workoutNotificationsEnabled)
            .animation(.default, value: appSettings.playTimerSound)
            .animation(.default, value: isWorkoutGroupExpanded)
            .animation(.default, value: isWorkoutRestGroupExpanded)
            .navigationTitle(.more)
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen(.more)
            .onAppear {
                if aboutInfopost == nil {
                    aboutInfopost = statusManager.infopostsService.loadAboutInfopost()
                }
            }
            .onChange(of: appSettings.workoutNotificationsEnabled) { _, _ in
                analytics.log(.userAction(action: .toggleWorkoutNotifications))
            }
            .onChange(of: appSettings.restTime) { _, newValue in
                analytics.log(.userAction(action: .selectRestTime(seconds: newValue)))
            }
        }
    }

    private var appThemeAndIconButton: some View {
        NavigationLink(destination: ThemeIconScreen(analytics: analytics)) {
            Text(.themeIconScreenTitle)
        }
        .accessibilityIdentifier("appThemeIconButton")
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
                analytics.log(.userAction(action: .openLanguageSettings))
                let settingsUrl = URL(string: UIApplication.openSettingsURLString)
                URLOpener.open(settingsUrl)
            }
        }
    }

    #if DEBUG
    private var debugCurrentDayPicker: some View {
        Picker(.currentDay, selection: .init(
            get: { statusManager.currentDayCalculator?.currentDay ?? 1 },
            set: { statusManager.setCurrentDayForDebug($0) }
        )) {
            ForEach(1 ... 100, id: \.self) { day in
                Text(.day(number: day)).tag(day)
            }
        }
        .pickerStyle(.navigationLink)
    }
    #endif

    private var workoutSettingsGroup: some View {
        DisclosureGroup(isExpanded: $isWorkoutGroupExpanded) {
            @Bindable var settings = appSettings
            NavigationLink(destination: CustomExercisesScreen()) {
                Text(.customExercises)
            }
            .accessibilityIdentifier("customExercisesButton")
            notificationToggle
            if settings.workoutNotificationsEnabled {
                makeNotificationTimePicker(
                    $settings.workoutNotificationTime
                )
            }
            DisclosureGroup(.moreScreenRestGroup, isExpanded: $isWorkoutRestGroupExpanded) {
                makeRestTimePicker($settings.restTime)
                makeTimerSoundToggle($settings.playTimerSound)
                if settings.playTimerSound {
                    makeTimerSoundPicker($settings.timerSound)
                }
                if UIDevice.current.userInterfaceIdiom == .phone {
                    makeVibrateToggle($settings.vibrate)
                }
            }
        } label: {
            Text(.moreScreenWorkoutGroup)
                .accessibilityIdentifier("moreScreenWorkoutGroup")
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

    private func makeTimerSoundPicker(_ value: Binding<TimerSound>) -> some View {
        Picker(.moreScreenTimerSound, selection: value) {
            ForEach(TimerSound.allCases, id: \.self) { sound in
                Text(sound.displayName).tag(sound)
            }
        }
        .pickerStyle(.navigationLink)
    }

    private func makeRestTimePicker(_ value: Binding<Int>) -> some View {
        Picker(.restTimePicker, selection: value) {
            ForEach(Constants.restPickerOptions, id: \.self) { seconds in
                Text(RestTimeComponents(totalSeconds: seconds).localizedString).tag(seconds)
            }
        }
        .pickerStyle(.navigationLink)
    }

    private var feedbackButton: some View {
        Button(.sendFeedback) {
            analytics.log(.userAction(action: .openFeedback))
            appSettings.sendFeedback()
        }
        .accessibilityIdentifier("sendFeedbackButton")
    }

    private var resetProgramButton: some View {
        Button(.moreScreenResetProgramButton) {
            analytics.log(.userAction(action: .openResetProgramDialog))
            showResetDialog = true
        }
        .confirmationDialog(
            .moreScreenResetProgramDialogTitle,
            isPresented: $showResetDialog,
            titleVisibility: .visible
        ) {
            Button(.moreScreenResetProgramDialogConfirm, role: .destructive) {
                analytics.log(.userAction(action: .confirmResetProgram))
                Task {
                    await statusManager.resetProgram()
                }
            }
        } message: {
            Text(.moreScreenResetProgramDialogMessage)
        }
    }

    @ViewBuilder
    private var rateAppButton: some View {
        if let appReviewLink = Constants.appReviewURL {
            Link(.rateTheApp, destination: appReviewLink)
                .accessibilityIdentifier("rateAppButton")
        }
    }

    @ViewBuilder
    private var officialSiteButton: some View {
        if let officialSiteLink = Constants.workoutSuURL {
            Link(.officialWebsite, destination: officialSiteLink)
                .accessibilityIdentifier("officialSiteButton")
        }
    }

    @ViewBuilder
    private var shareAppButton: some View {
        if let model = ShareAppURL(localeIdentifier: locale.identifier, appId: Constants.appId) {
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
        if let githubLink = Constants.swParksAppURL {
            Link(.streetWorkoutParks, destination: githubLink)
                .accessibilityIdentifier("swParksButton")
        }
    }

    @ViewBuilder
    private var daysCounterButton: some View {
        if let daysCounterLink = Constants.daysCounterAppURL {
            Link(.daysCounter, destination: daysCounterLink)
                .accessibilityIdentifier("daysCounterButton")
        }
    }

    @ViewBuilder
    private var githubButton: some View {
        if let githubLink = Constants.githubPageURL {
            Link(.gitHub, destination: githubLink)
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

    private var syncJournalButton: some View {
        NavigationLink(destination: SyncJournalScreen()) {
            Text(.moreScreenSyncJournalButton)
        }
        .accessibilityIdentifier("syncJournalButton")
    }

    private var logoutButton: some View {
        Button(.logOut) {
            showLogoutDialog = true
        }
        .confirmationDialog(
            .alertLogout,
            isPresented: $showLogoutDialog,
            titleVisibility: .visible
        ) {
            Button(.logOut, role: .destructive) {
                analytics.log(.userAction(action: .logout))
                authHelper.triggerLogout()
            }
        }
    }
}

private extension MoreScreen {
    enum Key: String {
        case isWorkoutGroupExpanded = "WorkoutSettings.Expanded"
        case isWorkoutRestGroupExpanded = "WorkoutSettings.Rest.Expanded"
    }
}

#if DEBUG
#Preview("День 1") {
    MoreScreen(user: .preview)
        .environment(AppSettings())
        .environment(StatusManager.preview)
        .environment(\.currentDay, 1)
        .modelContainer(PreviewModelContainer.make(with: .preview))
}

#Preview("День 2") {
    MoreScreen(user: .preview)
        .environment(AppSettings())
        .environment(StatusManager.preview)
        .environment(\.currentDay, 2)
        .modelContainer(PreviewModelContainer.make(with: .preview))
}
#endif
