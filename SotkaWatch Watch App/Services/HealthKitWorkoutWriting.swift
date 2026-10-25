import Foundation

/// Контракт сервиса записи тренировок в HealthKit.
protocol HealthKitWorkoutWriting {
    /// Однократный запрос разрешения на запись тренировок (вызывается из главного потока — показывает системный диалог)
    func requestWriteAuthorization() async

    /// Сохранение завершённой тренировки по датам (тип активности — кросс-тренинг)
    func saveWorkout(startDate: Date, endDate: Date) async
}
