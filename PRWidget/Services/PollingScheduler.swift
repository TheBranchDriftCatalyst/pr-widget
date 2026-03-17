import Foundation
import Observation
import CatalystSwift

@MainActor
@Observable
final class PollingScheduler {
    private enum Keys {
        static let interval = Persisted<Double>("PArr.pollInterval", default: 120)
        static let isEnabled = Persisted<Bool>("PArr.pollEnabled", default: true)
    }

    private(set) var isPolling = false

    var interval: TimeInterval {
        didSet { Keys.interval.save(interval); restartIfNeeded() }
    }

    var isEnabled: Bool {
        didSet { Keys.isEnabled.save(isEnabled); isEnabled ? restartIfNeeded() : stop() }
    }

    private var pollingTask: Task<Void, Never>?
    private var action: (@Sendable () async -> Void)?

    init() {
        self.interval = Keys.interval.load()
        self.isEnabled = Keys.isEnabled.load()
    }

    func start(action: @escaping @Sendable () async -> Void) {
        self.action = action
        guard isEnabled else { return }
        schedulePolling()
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        isPolling = false
    }

    private func restartIfNeeded() {
        guard action != nil, isEnabled else { return }
        stop()
        schedulePolling()
    }

    private func schedulePolling() {
        stop()
        pollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.interval ?? 120))
                guard let self, !Task.isCancelled, let action = self.action else { break }
                self.isPolling = true
                await action()
                self.isPolling = false
            }
        }
    }
}
