//
//  StatusManager.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 25.05.2025.
//

import Foundation
import Observation
import SWUtils
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
            let siteStartDate = currentRun.date
            switch (startDate, siteStartDate) {
            case (.none, .none):
                logger.info("Сотку еще не стартовали")
                try await start(client: client)
            case let (.none, .some(date)):
                // TODO: syncUsingSiteData
                // Сайт - источник истины
                logger.info("Статус загрузили, дата старта есть только на сайте: \(date.description)")
                self.startDate = date
            case let (.some(date), .none):
                // TODO: syncUsingAppData
                // Приложение - источник истины
                logger.info("Статус загрузили, на сайте нет даты старта, а в приложении есть: \(date.description)")
                try await start(client: client)
            case let (.some(appDate), .some(siteDate)):
                /*
                 Если даты без учета часов совпадают, то делаем обычную синхронизацию,
                 иначе - показываем алерт с предложением выбрать источник истины
                 showSyncOptionsWithSiteDate
                 */
                logger.info("Статус загружен, дата старта в приложении: \(appDate.description), и на сайте: \(siteDate.description)")
                break
            }
            try await start(client: client)
        } catch {
            logger.error("\(error.localizedDescription)")
        }
        isLoading = false
    }
    
    @discardableResult
    func start(client: StatusClient) async throws -> CurrentRun {
        let isoDateString = DateFormatterService.stringFromFullDate(.now, iso: true)
        let currentRun = try await client.start(date: isoDateString)
        // TODO: синхронизировать дневник и прогресс (посты, параметры, фото)
        return currentRun
    }
    
    func syncWithSiteData(client: StatusClient, siteDate: Date? = nil) async {
        if let siteDate {
            self.startDate = siteDate
        } else {
            await getStatus(client: client)
        }
        // TODO: синхронизировать дневник и прогресс (посты, параметры, фото)
    }
    
    func didLogout() {
        startDate = nil
    }
}

private extension StatusManager {
    enum Key: String {
        /// Дата начала сотки
        ///
        /// Значение взял из старого приложения
        case startDate = "WorkoutStartDate"
    }
}
