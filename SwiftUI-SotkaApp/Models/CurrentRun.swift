//
//  CurrentRun.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 25.05.2025.
//

import Foundation

/// Текущее прохождение программы
struct CurrentRun: Decodable {
    /// Дата начала программы
    ///
    /// `nil`, если пользователь не стартовал сотку
    let date: Date?
}
