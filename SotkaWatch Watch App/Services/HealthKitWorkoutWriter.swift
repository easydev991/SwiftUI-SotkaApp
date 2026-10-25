import Foundation
import HealthKit
import OSLog

/// Сервис записи тренировок в HealthKit.
/// Простая запись `HKWorkout` (кросс-тренинг) по датам через `HKWorkoutBuilder`, без живой сессии
/// (живая сессия с пульсом и калориями — при будущем расширении). Best-effort: ошибки логируются
/// и не прерывают сохранение тренировки в SwiftData.
@MainActor
final class HealthKitWorkoutWriter: HealthKitWorkoutWriting {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
        category: String(describing: HealthKitWorkoutWriter.self)
    )

    private let healthStore = HKHealthStore()

    func requestWriteAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.warning("HealthKit недоступен на устройстве — запрос разрешения на запись пропущен")
            return
        }
        do {
            try await healthStore.requestAuthorization(toShare: [HKWorkoutType.workoutType()], read: [])
            logger.info("Разрешение на запись тренировок в HealthKit получено/запрошено")
        } catch {
            logger.error("Ошибка запроса разрешения на запись в HealthKit: \(error.localizedDescription)")
        }
    }

    func saveWorkout(startDate: Date, endDate: Date) async {
        let startText = startDate.formatted(date: .abbreviated, time: .standard)
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.warning("HealthKit недоступен на устройстве — тренировка (начало \(startText)) не записана")
            return
        }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .crossTraining
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)
        do {
            try await builder.beginCollection(at: startDate)
            try await builder.endCollection(at: endDate)
            let workout = try await builder.finishWorkout()
            logger.info("Тренировка сохранена в HealthKit: начало \(startText), длительность \(workout?.duration ?? 0) сек")
        } catch {
            logger.error("Ошибка сохранения тренировки в HealthKit (начало \(startText)): \(error.localizedDescription)")
        }
    }
}
