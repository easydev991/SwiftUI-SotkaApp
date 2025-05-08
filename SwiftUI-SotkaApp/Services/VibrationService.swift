//
//  VibrationService.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 08.05.2025.
//

import UIKit
import OSLog

struct VibrationService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: VibrationService.self)
    )
    
    @MainActor func perform() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        logger.debug("Выполняем вибрацию")
    }
}
