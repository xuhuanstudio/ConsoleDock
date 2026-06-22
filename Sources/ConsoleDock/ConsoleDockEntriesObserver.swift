import Foundation

final class ConsoleDockEntriesObserver {
    typealias SnapshotHandler = ([ConsoleDock.LogEntry]) -> Void

    private let notificationCenter: NotificationCenter
    private let deliveryQueue: DispatchQueue
    private let handler: SnapshotHandler
    private let lock = NSLock()
    private var token: NSObjectProtocol?
    private var invalidated = false
    private var deliveryPending = false

    init(
        notificationCenter: NotificationCenter = .default,
        deliveryQueue: DispatchQueue = .main,
        handler: @escaping SnapshotHandler
    ) {
        self.notificationCenter = notificationCenter
        self.deliveryQueue = deliveryQueue
        self.handler = handler
        token = notificationCenter.addObserver(
            forName: ConsoleDock.entriesDidChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.scheduleSnapshot()
        }
        scheduleSnapshot()
    }

    deinit {
        invalidate()
    }

    func invalidate() {
        let observerToken: NSObjectProtocol?
        lock.lock()
        invalidated = true
        deliveryPending = false
        observerToken = token
        token = nil
        lock.unlock()

        if let observerToken {
            notificationCenter.removeObserver(observerToken)
        }
    }

    private func scheduleSnapshot() {
        lock.lock()
        guard !invalidated, !deliveryPending else {
            lock.unlock()
            return
        }
        deliveryPending = true
        lock.unlock()

        deliveryQueue.async { [weak self] in
            self?.deliverSnapshot()
        }
    }

    private func deliverSnapshot() {
        lock.lock()
        guard !invalidated else {
            lock.unlock()
            return
        }
        deliveryPending = false
        lock.unlock()

        handler(ConsoleDock.entries)
    }
}
