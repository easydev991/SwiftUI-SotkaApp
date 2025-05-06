//
//  MoreScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 04.05.2025.
//

import SwiftUI

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
                    notificationToggle
                    if settings.workoutNotificationsEnabled {
                        makeNotificationTimePicker(
                            $settings.workoutNotificationTime
                        )
                    }
                }
                Section("About app") {
                    rateAppButton
                    feedbackButton
                    officialSiteButton
                    shareAppButton
                    appVersionText
                }
            }
            .animation(.default, value: appSettings.workoutNotificationsEnabled)
            .navigationTitle("More")
            .alert(
                isPresented: $settings.showNotificationError,
                error: appSettings.notificationError
            ) {
                Button("Cancel") {}
                Button("Go to settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
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

    private var notificationToggle: some View {
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

    private var feedbackButton: some View {
        Button("Send feedback", action: FeedbackSender.sendFeedback)
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
}



#if DEBUG
#Preview {
    MoreScreen()
        .environment(AppSettings())
}
#endif
