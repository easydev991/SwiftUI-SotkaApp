import Foundation
import OSLog
import SwiftData
import SwiftUI

/// Прогресс пользователя
@Model
final class UserProgress {
    /// Совпадает с номером дня
    var id: Int
    var pullUps: Int?
    var pushUps: Int?
    var squats: Int?
    var weight: Float?
    @available(*, deprecated, message: "Sync flag, kept for schema stability (server closed 2026-08-01).")
    var isSynced = false
    var shouldDelete = false
    @available(*, deprecated, message: "Sync timestamp, kept for schema stability (server closed 2026-08-01).")
    var lastModified = Date.now

    /// Связь с пользователем
    @Relationship(inverse: \User.progressResults) var user: User?

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
        self.lastModified = lastModified
    }

    /// Проверяет, заполнены ли все результаты прогресса
    var isMetricsFilled: Bool {
        guard let pullUps, let pushUps, let squats, let weight else {
            return false
        }
        return [pullUps, pushUps, squats].allSatisfy { $0 > 0 } && weight > 0
    }

    /// Проверяет, есть ли в прогрессе хотя бы какие-то данные (больше нуля)
    var hasAnyMetricsData: Bool {
        let intValues = [pullUps, pushUps, squats].compactMap(\.self)
        let hasWeightInfo = if let weight {
            weight > 0
        } else {
            false
        }
        return intValues.contains(where: { $0 > 0 }) || hasWeightInfo
    }
}

extension UserProgress {
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

        var localizedTitle: String {
            switch self {
            case .one: String(localized: .progressSectionStart)
            case .two: String(localized: .progressSectionMiddle)
            case .three: String(localized: .progressSectionEnd)
            }
        }
    }
}

// MARK: - ProgressDataType

extension UserProgress {
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
            return formattedWeight(weight) + String(localized: .progressWeightUnit)
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

    func setMetricsData(_ model: TempMetricsModel) {
        pullUps = model.pullUps.isEmpty ? nil : Int(model.pullUps)
        pushUps = model.pushUps.isEmpty ? nil : Int(model.pushUps)
        squats = model.squats.isEmpty ? nil : Int(model.squats)
        weight = model.weight.isEmpty ? nil : Float.fromUIString(model.weight)
        isSynced = false
        shouldDelete = false
        lastModified = .now
    }

    /// Проверяет, является ли прогресс "пустым" (нет значимых данных)
    ///
    /// Возвращает `true`, если все показатели равны нулю или отсутствуют, и нет фотографий
    var isEmpty: Bool {
        !hasAnyMetricsData && !hasAnyPhotoDataIncludingURLs
    }

    /// Проверяет, можно ли удалить прогресс (есть данные упражнений или фотографии)
    var canBeDeleted: Bool {
        hasAnyMetricsData || hasAnyPhotoDataIncludingURLs
    }
}

extension UserProgress {
    var tempPhotoItems: [TempPhotoModel] {
        ProgressPhotoType.allCases.map { type in
            .init(
                type: type,
                urlString: getPhotoURL(type),
                data: getPhotoData(type)
            )
        }
    }

    func setPhotosData(_ photos: [TempPhotoModel]) {
        photos.forEach { photo in
            setPhotoData(photo.data, type: photo.type)
        }
    }

    func setPhotoData(_ data: Data?, type: ProgressPhotoType) {
        switch type {
        case .front: dataPhotoFront = data
        case .back: dataPhotoBack = data
        case .side: dataPhotoSide = data
        }
        lastModified = .now
        isSynced = false
    }

    /// Достает данные изображения указанного типа
    /// - Parameter type: Тип фотографии
    /// - Returns: Данные для фотографии или `nil`, если фото отмечено для удаления
    func getPhotoData(_ type: ProgressPhotoType) -> Data? {
        let data: Data? = switch type {
        case .front:
            dataPhotoFront
        case .back:
            dataPhotoBack
        case .side:
            dataPhotoSide
        }
        return shouldDeletePhoto(type) ? nil : data
    }

    /// Проверяет, есть ли локальные данные хотя бы для одной фотографии
    var hasAnyPhotoData: Bool {
        dataPhotoFront != nil || dataPhotoBack != nil || dataPhotoSide != nil
    }

    /// Проверяет, есть ли данные хотя бы для одной фотографии (локальные или URL)
    var hasAnyPhotoDataIncludingURLs: Bool {
        hasAnyPhotoData || urlPhotoFront != nil || urlPhotoBack != nil || urlPhotoSide != nil
    }

    /// Проверяет, нужно ли удалить фотографию определенного типа
    func shouldDeletePhoto(_ type: ProgressPhotoType) -> Bool {
        let data: Data? = switch type {
        case .front: dataPhotoFront
        case .back: dataPhotoBack
        case .side: dataPhotoSide
        }
        return data == UserProgress.DELETED_DATA
    }

    /// Достает `stringUrl` фотографии указанного типа или `nil`,
    /// если фото отмечено для удаления
    func getPhotoURL(_ type: ProgressPhotoType) -> String? {
        let urlString: String? = switch type {
        case .front:
            urlPhotoFront
        case .back:
            urlPhotoBack
        case .side:
            urlPhotoSide
        }
        return shouldDeletePhoto(type) ? nil : urlString
    }
}

extension UserProgress: CustomStringConvertible {
    var description: String {
        let pullUpsDescription = "pullUps: \(pullUps ?? 0)"
        let pushUpsDescription = "pushUps: \(pushUps ?? 0)"
        let squatsDescription = "squats: \(squats ?? 0)"
        let weightDescription = "weight: \(weight ?? 0)"
        let lastModifiedDescription = "lastModified: \(lastModified)"
        let photoFrontDescription = "urlPhotoFront: \(getPhotoURL(.front) ?? "отсутствует"), hasData: \(getPhotoData(.front) != nil)"
        let photoBackDescription = "urlPhotoBack: \(getPhotoURL(.back) ?? "отсутствует"), hasData: \(getPhotoData(.back) != nil)"
        let photoSideDescription = "urlPhotoSide: \(getPhotoURL(.side) ?? "отсутствует"), hasData: \(getPhotoData(.side) != nil)"
        return [
            pullUpsDescription,
            pushUpsDescription,
            squatsDescription,
            weightDescription,
            lastModifiedDescription,
            photoFrontDescription,
            photoBackDescription,
            photoSideDescription
        ].joined(separator: ", ")
    }
}

private extension UserProgress {
    /// Форматирует вес для отображения, убирая trailing zeros
    /// - Parameter weight: Вес для форматирования
    /// - Returns: Отформатированная строка веса без trailing zeros (например, "70" вместо "70.0", но "75.5" остается "75.5")
    func formattedWeight(_ weight: Float) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false

        guard let formattedString = formatter.string(from: NSNumber(value: weight)) else {
            // Fallback на стандартное форматирование, если NumberFormatter вернул nil
            let formatted = String(format: "%.1f", weight)
            // Убираем trailing zero и точку/запятую
            return formatted.replacingOccurrences(of: "\\.0$", with: "", options: .regularExpression)
                .replacingOccurrences(of: ",0$", with: "", options: .regularExpression)
        }

        // Явно убираем trailing zero и разделитель, если они есть
        return formattedString
            .replacingOccurrences(of: "\\.0$", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",0$", with: "", options: .regularExpression)
    }
}

// MARK: - Constants
extension UserProgress {
    /// Константа для пометки удаленных фотографий
    ///
    /// Только байт "d", как в старом приложении
    static let DELETED_DATA = Data([0x64])
}
