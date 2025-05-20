//
//  MoreScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 04.05.2025.
//

import SwiftUI
import SWUtils

struct MoreScreen: View {
    @Environment(\.locale) private var locale
    @Environment(AppSettings.self) private var appSettings
    private let appId = "id1148574738"

    var body: some View {
        NavigationStack {
            @Bindable var settings = appSettings
            List {
                Section("Settings") {
                    appThemePicker
                    appLanguageButton
                    notificationToggle
                    if settings.workoutNotificationsEnabled {
                        makeNotificationTimePicker(
                            $settings.workoutNotificationTime
                        )
                    }
                    makeTimerSoundToggle($settings.playTimerSound)
                    makeVibrateToggle($settings.vibrate)
                }
                Section("About app") {
                    rateAppButton
                    feedbackButton
                    officialSiteButton
                    shareAppButton
                    appVersionText
                }
                Section("Other apps") {
                    swParksButton
                }
                Section("Support the project") {
                    workoutShopButton
                    githubButton
                }
            }
            .animation(.default, value: appSettings.workoutNotificationsEnabled)
            .navigationTitle("More")
        }
    }

    @ViewBuilder
    private var appThemePicker: some View {
        @Bindable var settings = appSettings
        Picker("App theme", selection: $settings.appTheme) {
            ForEach(AppTheme.allCases) {
                Text($0.title).tag($0)
            }
        }
        .accessibilityIdentifier("appThemeButton")
    }
    
    @ViewBuilder
    private var appLanguageButton: some View {
        @Bindable var settings = appSettings
        Picker("App language", selection: .constant(AppLanguage.makeCurrentValue(locale.identifier))) {
            ForEach(AppLanguage.allCases) {
                Text($0.title).tag($0)
            }
        }
        .overlay { Rectangle().opacity(0.0001) }
        .onTapGesture {
            settings.showLanguageAlert.toggle()
        }
        .alert("Alert.language", isPresented: $settings.showLanguageAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Go to settings") {
                let settingsUrl = URL(string: UIApplication.openSettingsURLString)
                URLOpener.open(settingsUrl)
            }
        }
    }

    @ViewBuilder
    private var notificationToggle: some View {
        @Bindable var settings = appSettings
        Toggle(
            "Workout notifications",
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
            "Notification Time",
            selection: value,
            displayedComponents: .hourAndMinute
        )
    }
    
    private func makeTimerSoundToggle(_ value: Binding<Bool>) -> some View {
        Toggle("TimerSoundToggle", isOn: value)
    }
    
    private func makeVibrateToggle(_ value: Binding<Bool>) -> some View {
        Toggle("TimerVibrateToggle", isOn: value)
    }

    private var feedbackButton: some View {
        Button("Send feedback", action: appSettings.sendFeedback)
            .accessibilityIdentifier("sendFeedbackButton")
    }

    @ViewBuilder
    private var rateAppButton: some View {
        if let appReviewLink = URL(string: "https://apps.apple.com/app/\(appId)?action=write-review") {
            Link("Rate the app", destination: appReviewLink)
                .accessibilityIdentifier("rateAppButton")
        }
    }
    
    @ViewBuilder
    private var officialSiteButton: some View {
        if let officialSiteLink = URL(string: "https://workout.su") {
            Link("Official website", destination: officialSiteLink)
                .accessibilityIdentifier("officialSiteButton")
        }
    }

    @ViewBuilder
    private var shareAppButton: some View {
        let languageCode = locale.identifier.split(separator: "_").first == "ru" ? "ru" : "us"
        if let appStoreLink = URL(string: "https://apps.apple.com/\(languageCode)/app/\(appId)") {
            ShareLink(item: appStoreLink) {
                Text("Share the app")
            }
            .accessibilityIdentifier("shareAppButton")
        }
    }

    private var appVersionText: some View {
        HStack {
            Text("App version")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(appSettings.appVersion)")
        }
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var swParksButton: some View {
        if let githubLink = URL(string: "https://apps.apple.com/app/id1035159361") {
            Link("Street Workout: Parks", destination: githubLink)
                .accessibilityIdentifier("swParksButton")
        }
    }
    
    @ViewBuilder
    private var workoutShopButton: some View {
        if let shopLink = URL(string: "https://workoutshop.ru/?utm_source=iOS&utm_medium=100&utm_campaign=NASTROIKI") {
            Link("WORKOUT shop", destination: shopLink)
                .accessibilityIdentifier("workoutShopButton")
        }
    }
    
    @ViewBuilder
    private var githubButton: some View {
        if let githubLink = URL(string: "https://github.com/easydev991/SwiftUI-SotkaApp") {
            Link("GitHub page", destination: githubLink)
                .accessibilityIdentifier("githubButton")
        }
    }
}

#if DEBUG
#Preview {
    MoreScreen()
        .environment(AppSettings())
}
#endif
