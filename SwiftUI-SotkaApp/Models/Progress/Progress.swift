import Foundation
import OSLog
import SwiftData
import SwiftUI
import SWUtils

private let logger = Logger(subsystem: "SotkaApp", category: "Progress")

/// Прогресс пользователя
@Model
final class Progress {
    /// Совпадает с номером дня
    var id: Int
    var pullUps: Int?
    var pushUps: Int?
    var squats: Int?
    var weight: Float?
    var isSynced = false
    var shouldDelete = false
    var lastModified = Date.now

    /// Связь с пользователем
    @Relationship(inverse: \User.progressResults) var user: User?

    // MARK: - Поля для фотографий прогресса (новая архитектура)

    /// URL фотографии спереди
    var urlPhotoFront: String?

    /// URL фотографии сзади
    var urlPhotoBack: String?

    /// URL фотографии сбоку
    var urlPhotoSide: String?

    /// Локальные данные изображения спереди (кэш)
    var dataPhotoFront: Data?

    /// Локальные данные изображения сзади (кэш)
    var dataPhotoBack: Data?

    /// Локальные данные изображения сбоку (кэш)
    var dataPhotoSide: Data?

    /// Флаги пометки фото для удаления с сервера
    var shouldDeletePhotoFront = false
    var shouldDeletePhotoBack = false
    var shouldDeletePhotoSide = false

    init(
        id: Int,
        pullUps: Int? = nil,
        pushUps: Int? = nil,
        squats: Int? = nil,
        weight: Float? = nil,
        urlPhotoFront: String? = nil,
        urlPhotoBack: String? = nil,
        urlPhotoSide: String? = nil,
        dataPhotoFront: Data? = nil,
        dataPhotoBack: Data? = nil,
        dataPhotoSide: Data? = nil,
        shouldDeletePhotoFront: Bool = false,
        shouldDeletePhotoBack: Bool = false,
        shouldDeletePhotoSide: Bool = false,
        lastModified: Date = .now
    ) {
        self.id = id
        self.pullUps = pullUps
        self.pushUps = pushUps
        self.squats = squats
        self.weight = weight
        self.urlPhotoFront = urlPhotoFront
        self.urlPhotoBack = urlPhotoBack
        self.urlPhotoSide = urlPhotoSide
        self.dataPhotoBack = dataPhotoBack
        self.dataPhotoSide = dataPhotoSide
        self.dataPhotoFront = dataPhotoFront
        self.shouldDeletePhotoFront = shouldDeletePhotoFront
        self.shouldDeletePhotoBack = shouldDeletePhotoBack
        self.shouldDeletePhotoSide = shouldDeletePhotoSide
        self.lastModified = lastModified
    }

    /// Проверяет, заполнены ли все результаты прогресса
    var isFilled: Bool {
        guard let pullUps, let pushUps, let squats, let weight else {
            return false
        }
        return [pullUps, pushUps, squats].allSatisfy { $0 > 0 } && weight > 0
    }

    /// Проверяет, есть ли в прогрессе хотя бы какие-то данные (больше нуля)
    var hasAnyData: Bool {
        (pullUps.map { $0 > 0 } ?? false) ||
            (pushUps.map { $0 > 0 } ?? false) ||
            (squats.map { $0 > 0 } ?? false) ||
            (weight.map { $0 > 0 } ?? false)
    }

    /// Блок программы на основе номера дня
    var section: Section {
        Section(day: id)
    }

    /// Создает Progress из ProgressResponse
    convenience init(from response: ProgressResponse, user: User) {
        let lastModified = response.modifyDate.flatMap {
            DateFormatterService.dateFromString($0, format: .serverDateTimeSec)
        } ?? DateFormatterService.dateFromString(response.createDate, format: .serverDateTimeSec)
        self.init(
            id: response.id,
            pullUps: response.pullups,
            pushUps: response.pushups,
            squats: response.squats,
            weight: response.weight,
            urlPhotoFront: response.photoFront,
            urlPhotoBack: response.photoBack,
            urlPhotoSide: response.photoSide,
            lastModified: lastModified
        )
        self.user = user
        self.isSynced = true
        self.shouldDelete = false
    }

    /// Создает Progress из ProgressResponse с маппингом дня
    convenience init(from response: ProgressResponse, user: User, internalDay: Int) {
        let lastModified = response.modifyDate.flatMap {
            DateFormatterService.dateFromString($0, format: .serverDateTimeSec)
        } ?? DateFormatterService.dateFromString(response.createDate, format: .serverDateTimeSec)
        self.init(
            id: internalDay,
            pullUps: response.pullups,
            pushUps: response.pushups,
            squats: response.squats,
            weight: response.weight,
            urlPhotoFront: response.photoFront,
            urlPhotoBack: response.photoBack,
            urlPhotoSide: response.photoSide,
            lastModified: lastModified
        )
        self.user = user
        self.isSynced = true
        self.shouldDelete = false
    }
}

extension Progress {
    enum Section: Int, CaseIterable, Codable {
        /// Базовый блок
        case one = 1
        /// Продвинутый блок
        case two = 49
        /// Заключение
        case three = 100

        init(day: Int) {
            switch day {
            case 1 ... 48:
                self = .one
            case 49 ... 99:
                self = .two
            case 100...:
                self = .three
            default:
                self = .one
            }
        }
    }

    /// Маппинг внутренних дней приложения в внешние дни сервера
    ///
    /// Соответствует логике Android приложения и серверной архитектуре
    static func getExternalDayFromProgressId(_ internalId: Int) -> Int {
        switch internalId {
        case 1:
            1 // День 1 соответствует серверному дню 1
        case 49:
            49 // День 49 соответствует серверному дню 49 (контрольная точка)
        case 100:
            99 // День 100 соответствует серверному дню 99 (контрольная точка)
        default:
            internalId
        }
    }

    /// Маппинг внешних дней сервера во внутренние дни приложения
    ///
    /// Обратная функция для getExternalDayFromProgressId
    static func getInternalDayFromExternalDay(_ externalDay: Int) -> Int {
        switch externalDay {
        case 1:
            1 // Серверный день 1 соответствует внутреннему дню 1
        case 49:
            49 // Серверный день 49 соответствует внутреннему дню 49
        case 99:
            100 // Серверный день 99 соответствует внутреннему дню 100
        default:
            externalDay
        }
    }
}

// MARK: - ProgressDataType

extension Progress {
    /// Типы данных прогресса
    enum DataType: CaseIterable {
        case weight
        case pullUps
        case pushUps
        case squats

        /// Локализованное название типа данных
        var localizedTitle: String {
            switch self {
            case .weight: String(localized: .weight)
            case .pullUps: String(localized: ExerciseType.pullups.localizedTitle)
            case .pushUps: String(localized: ExerciseType.pushups.localizedTitle)
            case .squats: String(localized: ExerciseType.squats.localizedTitle)
            }
        }

        /// Иконка для типа данных
        var icon: Image {
            switch self {
            case .weight:
                Image(systemName: "scalemass.fill")
            case .pullUps:
                ExerciseType.pullups.image
            case .pushUps:
                ExerciseType.pushups.image
            case .squats:
                ExerciseType.squats.image
            }
        }
    }

    /// Получить отображаемое значение для указанного типа данных
    func displayedValue(for dataType: DataType) -> String {
        switch dataType {
        case .weight:
            guard let weight, weight > 0 else { return "—" }
            return String(format: String(localized: "Progress.Weight"), weight) + String(localized: .progressWeightUnit)
        case .pullUps:
            guard let pullUps, pullUps > 0 else { return "—" }
            return "\(pullUps)"
        case .pushUps:
            guard let pushUps, pushUps > 0 else { return "—" }
            return "\(pushUps)"
        case .squats:
            guard let squats, squats > 0 else { return "—" }
            return "\(squats)"
        }
    }

    // MARK: - New Photo Data Management Methods

    /// Устанавливает данные изображения для указанного типа (новая архитектура)
    func setPhotoData(_ type: PhotoType, data: Data) {
        switch type {
        case .front:
            dataPhotoFront = data
            shouldDeletePhotoFront = false // Сбрасываем флаг удаления при добавлении нового фото
        case .back:
            dataPhotoBack = data
            shouldDeletePhotoBack = false // Сбрасываем флаг удаления при добавлении нового фото
        case .side:
            dataPhotoSide = data
            shouldDeletePhotoSide = false // Сбрасываем флаг удаления при добавлении нового фото
        }
        lastModified = Date()
        isSynced = false
    }

    /// Получает данные изображения указанного типа (новая архитектура)
    func getPhotoData(_ type: PhotoType) -> Data? {
        switch type {
        case .front:
            dataPhotoFront
        case .back:
            dataPhotoBack
        case .side:
            dataPhotoSide
        }
    }

    /// Проверяет, есть ли локальные данные изображения указанного типа
    func hasPhotoData(_ type: PhotoType) -> Bool {
        getPhotoData(type) != nil
    }

    /// Удаляет локальные данные изображения указанного типа
    func deletePhotoData(_ type: PhotoType) {
        switch type {
        case .front:
            dataPhotoFront = nil
            urlPhotoFront = nil
            shouldDeletePhotoFront = true
        case .back:
            dataPhotoBack = nil
            urlPhotoBack = nil
            shouldDeletePhotoBack = true
        case .side:
            dataPhotoSide = nil
            urlPhotoSide = nil
            shouldDeletePhotoSide = true
        }
        lastModified = Date()
        isSynced = false
    }

    /// Проверяет, есть ли локальные данные хотя бы для одной фотографии
    var hasAnyPhotoData: Bool {
        dataPhotoFront != nil || dataPhotoBack != nil || dataPhotoSide != nil
    }

    /// Проверяет, есть ли локальные данные для всех трех фотографий
    var hasAllPhotoData: Bool {
        dataPhotoFront != nil && dataPhotoBack != nil && dataPhotoSide != nil
    }

    /// Устанавливает lastModified в соответствии с серверным временем (как в Android)
    /// Если modify_date равен null, используем create_date
    func updateLastModified(from response: ProgressResponse) {
        lastModified = response.modifyDate.flatMap {
            DateFormatterService.dateFromString($0, format: .serverDateTimeSec)
        } ?? DateFormatterService.dateFromString(response.createDate, format: .serverDateTimeSec)
    }

    /// Сбрасывает флаги удаления фото после успешной синхронизации
    func resetPhotoDeletionFlags() {
        shouldDeletePhotoFront = false
        shouldDeletePhotoBack = false
        shouldDeletePhotoSide = false
    }

    /// Проверяет, есть ли фотография указанного типа (URL или данные)
    func hasPhoto(_ type: PhotoType) -> Bool {
        switch type {
        case .front:
            dataPhotoFront != nil || urlPhotoFront != nil
        case .back:
            dataPhotoBack != nil || urlPhotoBack != nil
        case .side:
            dataPhotoSide != nil || urlPhotoSide != nil
        }
    }

    /// Получает URL фотографии указанного типа
    func getPhotoURL(_ type: PhotoType) -> String? {
        switch type {
        case .front:
            urlPhotoFront
        case .back:
            urlPhotoBack
        case .side:
            urlPhotoSide
        }
    }
}
