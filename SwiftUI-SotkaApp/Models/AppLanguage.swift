//
//  AppLanguage.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 10.05.2025.
//

import SwiftUI

enum AppLanguage: CaseIterable, Identifiable {
    var id: Self { self }
    case russian
    case english
    
    var title: LocalizedStringKey {
        self == .russian ? "Russian" : "English"
    }
    
    static func makeCurrentValue(_ localeIdentifier: String) -> AppLanguage {
        let isRussian = localeIdentifier.split(separator: "_").first == "ru"
        return isRussian ? .russian : .english
    }
}
