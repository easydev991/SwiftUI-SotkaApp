//
//  AppSettings.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 04.05.2025.
//

import SwiftUI
import Observation

@Observable final class AppSettings {
    var appTheme: AppTheme {
        get {
            access(keyPath: \.appTheme)
            let rawValue = UserDefaults.standard.integer(forKey: "appTheme")
            return .init(rawValue: rawValue) ?? .system
        }
        set {
            withMutation(keyPath: \.appTheme) {
                UserDefaults.standard.setValue(newValue.rawValue, forKey: "appTheme")
            }
        }
    }

    let appVersion = (
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
    ) ?? "4.0.0"
}

