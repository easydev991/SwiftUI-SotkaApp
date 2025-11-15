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
    @AppStorage(Key.isWorkoutGroupExpanded.rawValue) private var isWorkoutGroupExpanded = true
    @AppStorage(Key.isWorkoutRestGroupExpanded.rawValue) private var isWorkoutRestGroupExpanded = true
    @State private var aboutInfopost: Infopost?
    @State private var showResetDialog = false

    var body: some View {
        NavigationStack {
            List {
                Section(.settings) {
                    appThemePicker
                    appLanguageButton
                    #if DEBUG
                    debugCurrentDayPicker
                    #endif
                    workoutSettingsGroup
                    syncJournalButton
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
                }
                Section(.supportTheProject) {
                    workoutShopButton
                    githubButton
                }
            }
            .animation(.default, value: appSettings.workoutNotificationsEnabled)
            .animation(.default, value: appSettings.playTimerSound)
            .animation(.default, value: isWorkoutGroupExpanded)
            .animation(.default, value: isWorkoutRestGroupExpanded)
            .navigationTitle(.more)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if aboutInfopost == nil {
                    aboutInfopost = statusManager.infopostsService.loadAboutInfopost()
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
        DisclosureGroup(.moreScreenWorkoutGroup, isExpanded: $isWorkoutGroupExpanded) {
            @Bindable var settings = appSettings
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
                makeVibrateToggle($settings.vibrate)
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
                Text(.sec(seconds)).tag(seconds)
            }
        }
        .pickerStyle(.navigationLink)
    }

    private var feedbackButton: some View {
        Button(.sendFeedback) {
            appSettings.sendFeedback()
        }
        .accessibilityIdentifier("sendFeedbackButton")
    }

    private var resetProgramButton: some View {
        Button(.moreScreenResetProgramButton) {
            showResetDialog = true
        }
        .confirmationDialog(
            .moreScreenResetProgramDialogTitle,
            isPresented: $showResetDialog,
            titleVisibility: .visible
        ) {
            Button(.moreScreenResetProgramDialogConfirm, role: .destructive) {
                Task {
                    await statusManager.resetProgram(context: modelContext)
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
    private var workoutShopButton: some View {
        if let shopLink = Constants.workoutShopURL {
            Link(.workoutShop, destination: shopLink)
                .accessibilityIdentifier("workoutShopButton")
        }
    }

    @ViewBuilder
    private var githubButton: some View {
        if let githubLink = Constants.githubPageURL {
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

    private var syncJournalButton: some View {
        NavigationLink(destination: SyncJournalScreen()) {
            Text(.moreScreenSyncJournalButton)
        }
        .accessibilityIdentifier("syncJournalButton")
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
    MoreScreen()
        .environment(AppSettings())
        .environment(StatusManager.preview)
        .environment(\.currentDay, 1)
        .modelContainer(PreviewModelContainer.make(with: .preview))
}

#Preview("День 2") {
    MoreScreen()
        .environment(AppSettings())
        .environment(StatusManager.preview)
        .environment(\.currentDay, 2)
        .modelContainer(PreviewModelContainer.make(with: .preview))
}
#endif
