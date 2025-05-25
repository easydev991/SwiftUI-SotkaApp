//
//  StatusManager.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 25.05.2025.
//

import Foundation
import Observation
import OSLog

@MainActor
@Observable final class StatusManager {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: StatusManager.self)
    )
    private let defaults = UserDefaults.standard
    
    /// Дата старта сотки
    private(set) var startDate: Date? {
        get {
            access(keyPath: \.startDate)
            let storedTime = defaults.double(
                forKey: Key.startDate.rawValue
            )
            guard storedTime != 0 else {
                logger.debug("Обратились к startDate, но он не был установлен")
                return nil
            }
            return Date(timeIntervalSinceReferenceDate: storedTime)
        }
        set {
            withMutation(keyPath: \.startDate) {
                if let newValue {
                    defaults.set(
                        newValue.timeIntervalSinceReferenceDate,
                        forKey: Key.startDate.rawValue
                    )
                } else {
                    defaults.removeObject(forKey: Key.startDate.rawValue)
                }
            }
        }
    }
    
    private(set) var isLoading = false
    
    /// Получает статус прохождения пользователя
    /// - Parameters:
    ///   - client: Сервис для загрузки статуса
    func getStatus(client: StatusClient) async {
        guard !isLoading else { return }
        isLoading = true
        do {
            let currentRun = try await client.current()
            guard let startDate = currentRun.date else {
                // TODO: стартовать сотку
                logger.info("Сотку еще не стартовали")
                return
            }
            logger.info("Статус загружен: \(startDate.description)")
            self.startDate = startDate
        } catch {
            logger.error("\(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func didLogout() {
        startDate = nil
    }
}

private extension StatusManager {
    enum Key: String {
        case startDate
    }
}
