//
//  DayCalculator+.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 27.05.2025.
//

import Foundation

extension DayCalculator {
    init(previewDay: Int) {
        let currentDay = min(previewDay, 100)
        self.currentDay = currentDay
        self.daysLeft = 100 - currentDay
    }
}
