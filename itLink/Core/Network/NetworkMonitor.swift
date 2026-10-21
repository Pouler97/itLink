import Foundation
import Network

@MainActor
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    var onConnectivityRestored: (() -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.pouler.itLink.networkMonitor")
    private var wasDisconnected = false

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self else { return }
                if connected && self.wasDisconnected {
                    self.onConnectivityRestored?()
                }
                self.wasDisconnected = !connected
            }
        }
        monitor.start(queue: queue)
    }
}
