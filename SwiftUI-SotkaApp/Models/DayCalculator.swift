//
//  DayCalculator.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 26.05.2025.
//

import Foundation

struct DayCalculator {
    let currentDay: Int
    let daysLeft: Int
    
    init?(_ currentDay: Int?) {
        guard let currentDay else {
            return nil
        }
        self.currentDay = currentDay
        self.daysLeft = 100 - currentDay
    }
}
