import Foundation
import Network

@Observable
@MainActor
public final class NetworkStatus {
    private let monitor = NWPathMonitor()
    private var isConnected = false
    private(set) var isInitialized = false

    /// `true` - есть подключение, `false` - нет подключения
    /// Если статус не инициализирован, возвращает `true` (предполагается наличие подключения)
    public var isOnline: Bool {
        isInitialized ? isConnected : true
    }

    public init() {
        Task {
            for await path in monitor {
                await MainActor.run {
                    self.isConnected = path.status == .satisfied
                    if !self.isInitialized {
                        self.isInitialized = true
                    }
                }
            }
        }
        monitor.start(queue: .global(qos: .background))
    }

    deinit {
        monitor.cancel()
    }
}
