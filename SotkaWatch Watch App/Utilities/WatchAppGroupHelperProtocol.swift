import Foundation

/// Протокол для WatchAppGroupHelper для тестирования
protocol WatchAppGroupHelperProtocol {
    var isAuthorized: Bool { get }
    var startDate: Date? { get }
    var currentDay: Int? { get }
    var restTime: Int { get }
}

/// WatchAppGroupHelper соответствует протоколу
extension WatchAppGroupHelper: WatchAppGroupHelperProtocol {}
