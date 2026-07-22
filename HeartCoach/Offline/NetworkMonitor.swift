import Foundation
import Network

/// Monitors network connectivity and publishes changes.
/// One instance lives in AppContainer — never duplicated.
final class NetworkMonitor {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.behzad.heartcoach.network")
    private var continuation: AsyncStream<Bool>.Continuation?

    /// Emits true when connected, false when disconnected.
    let isConnectedStream: AsyncStream<Bool>

    private(set) var isCurrentlyConnected: Bool = false

    init() {
        var cont: AsyncStream<Bool>.Continuation!
        isConnectedStream = AsyncStream { cont = $0 }
        continuation = cont

        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            self?.isCurrentlyConnected = connected
            self?.continuation?.yield(connected)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
        continuation?.finish()
    }
}
