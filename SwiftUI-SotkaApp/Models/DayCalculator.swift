//
//  DayCalculator.swift
//  SwiftUI-SotkaApp
//
//  Created by Олег Еременко on 26.05.2025.
//

import Foundation
import SWUtils
import OSLog

struct DayCalculator {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: DayCalculator.self)
    )
    /// Номер текущего дня
    let currentDay: Int
    /// Количество дней, оставшихся для завершения программы
    let daysLeft: Int
    
    /// `true` - программа завершена, `false` - программа не завершена
    var isOver: Bool { currentDay == 100 }
    
    /// Инициализатор
    /// - Parameters:
    ///   - startDate: Дата старта сотки (на сайте или в приложении)
    ///   - endDate: Текущая дата, с которой нужно сравнить дату старта
    init?(_ startDate: Date?, _ endDate: Date) {
        guard let startDate else {
            let message = "Дата старта не настроена"
            logger.error("\(message)")
            return nil
        }
        let daysBetween = DateFormatterService.days(from: startDate, to: endDate)
        let currentDay = min(daysBetween + 1, 100)
        self.currentDay = currentDay
        self.daysLeft = 100 - currentDay
    }
}
