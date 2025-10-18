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

    /// Связь с фотографиями прогресса
    @Relationship(deleteRule: .cascade, inverse: \ProgressPhoto.progress)
    var photos: [ProgressPhoto] = []

    init(
        id: Int,
        pullUps: Int? = nil,
        pushUps: Int? = nil,
        squats: Int? = nil,
        weight: Float? = nil
    ) {
        self.id = id
        self.pullUps = pullUps
        self.pushUps = pushUps
        self.squats = squats
        self.weight = weight
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
        self.init(
            id: response.id,
            pullUps: response.pullups,
            pushUps: response.pushups,
            squats: response.squats,
            weight: response.weight
        )
        self.user = user
        // Если modify_date равен null, используем create_date
        self.lastModified = response.modifyDate.flatMap {
            DateFormatterService.dateFromString($0, format: .serverDateTimeSec)
        } ?? DateFormatterService.dateFromString(response.createDate, format: .serverDateTimeSec)
        self.isSynced = true
        self.shouldDelete = false

        // Создаем фотографии из ответа сервера, если они есть
        if let photoFrontUrl = response.photoFront {
            let frontPhoto = ProgressPhoto(type: .front, urlString: photoFrontUrl)
            frontPhoto.isSynced = true
            frontPhoto.progress = self
            photos.append(frontPhoto)
            logger.info("Progress: Создана фотография front с URL: \(photoFrontUrl)")
        }
        if let photoBackUrl = response.photoBack {
            let backPhoto = ProgressPhoto(type: .back, urlString: photoBackUrl)
            backPhoto.isSynced = true
            backPhoto.progress = self
            photos.append(backPhoto)
            logger.info("Progress: Создана фотография back с URL: \(photoBackUrl)")
        }
        if let photoSideUrl = response.photoSide {
            let sidePhoto = ProgressPhoto(type: .side, urlString: photoSideUrl)
            sidePhoto.isSynced = true
            sidePhoto.progress = self
            photos.append(sidePhoto)
            logger.info("Progress: Создана фотография side с URL: \(photoSideUrl)")
        }
    }

    /// Создает Progress из ProgressResponse с маппингом дня
    convenience init(from response: ProgressResponse, user: User, internalDay: Int) {
        self.init(
            id: internalDay,
            pullUps: response.pullups,
            pushUps: response.pushups,
            squats: response.squats,
            weight: response.weight
        )
        self.user = user
        // Если modify_date равен null, используем create_date
        self.lastModified = response.modifyDate.flatMap {
            DateFormatterService.dateFromString($0, format: .serverDateTimeSec)
        } ?? DateFormatterService.dateFromString(response.createDate, format: .serverDateTimeSec)
        self.isSynced = true
        self.shouldDelete = false

        // Создаем фотографии из ответа сервера, если они есть
        if let photoFrontUrl = response.photoFront {
            let frontPhoto = ProgressPhoto(type: .front, urlString: photoFrontUrl)
            frontPhoto.isSynced = true
            frontPhoto.progress = self
            photos.append(frontPhoto)
            logger.info("Progress: Создана фотография front с URL: \(photoFrontUrl)")
        }
        if let photoBackUrl = response.photoBack {
            let backPhoto = ProgressPhoto(type: .back, urlString: photoBackUrl)
            backPhoto.isSynced = true
            backPhoto.progress = self
            photos.append(backPhoto)
            logger.info("Progress: Создана фотография back с URL: \(photoBackUrl)")
        }
        if let photoSideUrl = response.photoSide {
            let sidePhoto = ProgressPhoto(type: .side, urlString: photoSideUrl)
            sidePhoto.isSynced = true
            sidePhoto.progress = self
            photos.append(sidePhoto)
            logger.info("Progress: Создана фотография side с URL: \(photoSideUrl)")
        }
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
        var localizedTitle: LocalizedStringKey {
            switch self {
            case .weight: "Weight"
            case .pullUps: ExerciseType.pullups.localizedTitle
            case .pushUps: ExerciseType.pushups.localizedTitle
            case .squats: ExerciseType.squats.localizedTitle
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
            return String(format: String(localized: "Progress.Weight"), weight) + String(localized: "Progress.WeightUnit")
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
}

// MARK: - Photos Management

extension Progress {
    // MARK: - Computed Properties
    var hasPhotos: Bool {
        !photos.filter { !$0.isDeleted }.isEmpty
    }

    var hasUnsyncedPhotos: Bool {
        photos.contains { !$0.isSynced && !$0.isDeleted }
    }

    var hasPhotosToDelete: Bool {
        photos.contains { $0.isDeleted }
    }

    // MARK: - Methods
    func getPhoto(_ type: PhotoType) -> ProgressPhoto? {
        let result = photos.first { $0.type == type && !$0.isDeleted }
        let photosCount = photos.count
        logger.info("Progress.getPhoto(\(type.rawValue)): найдено \(result != nil ? "да" : "нет"), всего фотографий: \(photosCount)")
        if let photo = result {
            logger
                .info(
                    "Progress.getPhoto: data=\(photo.data != nil ? "есть" : "нет"), urlString=\(photo.urlString ?? "нет"), isDeleted=\(photo.isDeleted)"
                )
        }
        return result
    }

    func setPhoto(_ type: PhotoType, data: Data) {
        if let existing = getPhoto(type) {
            existing.data = data
            existing.lastModified = Date()
            existing.isSynced = false
        } else {
            let newPhoto = ProgressPhoto(type: type, data: data)
            photos.append(newPhoto)
        }
    }

    func deletePhoto(_ type: PhotoType) throws {
        guard let photo = getPhoto(type) else {
            throw ProgressError.photoNotFound
        }
        photo.isDeleted = true
        photo.lastModified = Date()
        photo.isSynced = false
    }
}
