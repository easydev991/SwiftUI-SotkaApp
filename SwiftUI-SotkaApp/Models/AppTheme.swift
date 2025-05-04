//
//  AppTheme.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 04.05.2025.
//

import SwiftUI

enum AppTheme: Int, CaseIterable, Identifiable {
    var id: Int { rawValue }
    case system = 0
    case light = 1
    case dark = 2

    var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

