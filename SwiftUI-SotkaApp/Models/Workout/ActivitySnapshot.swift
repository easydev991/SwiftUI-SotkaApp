import Foundation

/// Снимок активности для безопасной конкурентной синхронизации без доступа к ModelContext
struct ActivitySnapshot: Hashable {
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
    let shouldDelete: Bool
    let trainings: [TrainingSnapshot]?
}

extension ActivitySnapshot {
    /// Снимок тренировки для конкурентной синхронизации
    struct TrainingSnapshot: Hashable {
        let count: Int?
        let typeId: Int?
        let customTypeId: String?
        let sortOrder: Int?
    }
}
