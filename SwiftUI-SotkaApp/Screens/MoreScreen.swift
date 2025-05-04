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
            List {
                appThemePicker
                rateAppButton
                feedbackButton
                shareAppButton
                appVersionText
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle("More")
    }

    private var appThemePicker: some View {
        Picker(
            "App theme",
            selection: .init(
                get: { appSettings.appTheme },
                set: { appSettings.appTheme = $0 }
            )
        ) {
            ForEach(AppTheme.allCases) {
                Text($0.title).tag($0)
            }
        }
        .accessibilityIdentifier("appThemeButton")
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
