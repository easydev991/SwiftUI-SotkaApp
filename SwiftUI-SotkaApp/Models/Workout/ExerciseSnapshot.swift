import Foundation
import SWUtils

/// Снимок упражнения для безопасной конкурентной синхронизации без доступа к ModelContext
struct ExerciseSnapshot: Sendable, Hashable {
    let id: String
    let name: String
    let imageId: Int
    let createDate: Date
    let modifyDate: Date
    let isSynced: Bool
    let shouldDelete: Bool
    let userId: Int?
}

extension ExerciseSnapshot {
    /// Преобразование снимка в CustomExerciseRequest для отправки на сервер
    var exerciseRequest: CustomExerciseRequest {
        CustomExerciseRequest(
            id: id,
            name: name,
            imageId: imageId,
            createDate: DateFormatterService.stringFromFullDate(createDate, format: .isoDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(modifyDate, format: .isoDateTimeSec),
            isHidden: false
        )
    }
}
