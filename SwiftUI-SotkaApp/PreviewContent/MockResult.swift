//
//  MockResult.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 23.05.2025.
//

import Foundation

/// Результат-заглушка для мок-сервисов
enum MockResult {
    case success
    case failure(error: Error = MockError())
}

extension MockResult {
    struct MockError: Error {}
}
