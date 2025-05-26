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
    private var startDate: Date? {
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
    /// Номер текущего дня сотки
    private(set) var currentDay: Int?
    
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
                await start(client: client, appDate: nil)
            case let (.some(date), .none):
                // Приложение - источник истины
                logger.info("Дата старта есть только в приложении: \(date.description)")
                await start(client: client, appDate: date)
            case let (.none, .some(date)):
                // Сайт - источник истины
                logger.info("Дата старта есть только на сайте: \(date.description)")
                await syncWithSiteDate(client: client, siteDate: date)
            case let (.some(appDate), .some(siteDate)):
                logger.info("Дата старта в приложении: \(appDate.description), и на сайте: \(siteDate.description)")
                if appDate.isTheSameDayIgnoringTime(siteDate) {
                    await syncJournalAndProgress()
                } else {
                    // TODO: showSyncOptionsWithSiteDate
                    logger.error("Показать алерт с предложением выбрать источник истины")
                }
            }
            guard let startDate else {
                let message = "Дата старта не настроена"
                logger.error("\(message)")
                assertionFailure(message)
                return
            }
            let daysBetween = DateFormatterService.days(from: startDate, to: .now)
            currentDay = min(daysBetween + 1, 100)
        } catch {
            logger.error("\(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func start(client: StatusClient, appDate: Date?) async {
        let newStartDate = appDate ?? .now
        let isoDateString = DateFormatterService.stringFromFullDate(newStartDate, iso: true)
        let currentRun = try? await client.start(date: isoDateString)
        startDate = if let siteStartDate = currentRun?.date {
            siteStartDate
        } else {
            newStartDate
        }
        await syncJournalAndProgress()
    }
    
    func syncWithSiteDate(client: StatusClient, siteDate: Date) async {
        self.startDate = siteDate
        await getStatus(client: client)
        await syncJournalAndProgress()
    }
    
    func didLogout() {
        startDate = nil
        currentDay = nil
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

private extension StatusManager {
    func syncJournalAndProgress() async {
        logger.error("Реализовать синхронизацию дневника и прогресса")
    }
}
