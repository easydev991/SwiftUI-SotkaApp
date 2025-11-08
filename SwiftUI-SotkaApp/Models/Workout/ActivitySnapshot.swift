import Foundation
import SWUtils

/// Снимок активности для безопасной конкурентной синхронизации без доступа к ModelContext
struct ActivitySnapshot: Sendable, Hashable {
    let day: Int
    let activityTypeRaw: Int?
    let count: Int?
    let plannedCount: Int?
    let executeTypeRaw: Int?
    let trainingTypeRaw: Int?
    let duration: Int?
    let comment: String?
    let createDate: Date
    let modifyDate: Date
    let isSynced: Bool
    let shouldDelete: Bool
    let userId: Int?
    let trainings: [TrainingSnapshot]?
}

extension ActivitySnapshot {
    /// Снимок тренировки для конкурентной синхронизации
    struct TrainingSnapshot: Sendable, Hashable {
        let count: Int?
        let typeId: Int?
        let customTypeId: String?
        let sortOrder: Int?
    }
}

extension ActivitySnapshot {
    /// Преобразование снимка в DayRequest для отправки на сервер
    var dayRequest: DayRequest {
        DayRequest(
            id: day,
            activityType: activityTypeRaw,
            count: count,
            plannedCount: plannedCount,
            executeType: executeTypeRaw,
            trainingType: trainingTypeRaw,
            createDate: DateFormatterService.stringFromFullDate(createDate, format: .isoDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(modifyDate, format: .isoDateTimeSec),
            duration: duration,
            comment: comment,
            trainings: trainings?.map { training in
                DayRequest.Training(
                    count: training.count,
                    typeId: training.typeId,
                    customTypeId: training.customTypeId,
                    sortOrder: training.sortOrder
                )
            }
        )
    }
}
