import Foundation
import Network
import Observation

@MainActor
@Observable
public final class NetworkStatus {
    public private(set) var isConnected = false
    private var monitorTask: Task<Void, Never>?
    
    public init() {
        startModernMonitoring()
    }
    
    private func startModernMonitoring() {
        let monitor = NetworkMonitorActor()
        monitorTask = Task {
            for await status in monitor.updates {
                self.isConnected = status
            }
        }
    }
}

private actor NetworkMonitorActor {
    private let monitor = NWPathMonitor()
    
    nonisolated var updates: AsyncStream<Bool> {
        AsyncStream { continuation in
            let handle = Task {
                await startMonitoring(continuation: continuation)
            }
            continuation.onTermination = { @Sendable _ in
                handle.cancel()
            }
        }
    }
    
    private func startMonitoring(continuation: AsyncStream<Bool>.Continuation) async {
        monitor.pathUpdateHandler = { path in
            continuation.yield(path.status == .satisfied)
        }
        monitor.start(queue: .global(qos: .background))
        await withTaskCancellationHandler {
            while !Task.isCancelled {
                await Task.yield()
            }
        } onCancel: {
            monitor.cancel()
            continuation.finish()
        }
    }
}
