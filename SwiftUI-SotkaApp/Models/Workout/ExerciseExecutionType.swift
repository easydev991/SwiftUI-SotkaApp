//
//  ExerciseExecutionType.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 14.05.2025.
//

import SwiftUI

/// Тип выполнения упражнений
enum ExerciseExecutionType {
    /// Круги
    case cycles
    /// Подходы
    case sets
    
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .cycles: "Cycles"
        case .sets: "Sets"
        }
    }
}
