import Foundation

/// Снимок упражнения для безопасной конкурентной синхронизации без доступа к ModelContext
struct ExerciseSnapshot: Hashable {
    let id: String
    let name: String
    let imageId: Int
    let createDate: Date
    let modifyDate: Date
    let isSynced: Bool
    let shouldDelete: Bool
    let userId: Int?
}
