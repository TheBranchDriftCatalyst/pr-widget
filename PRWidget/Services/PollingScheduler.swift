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

    private var timer: Timer?
    private var action: (() async -> Void)?

    init() {
        self.interval = Keys.interval.load()
        self.isEnabled = Keys.isEnabled.load()
    }

    func start(action: @escaping () async -> Void) {
        self.action = action
        guard isEnabled else { return }
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isPolling = false
    }

    private func restartIfNeeded() {
        guard action != nil, isEnabled else { return }
        stop()
        scheduleTimer()
    }

    private func scheduleTimer() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let action = self.action else { return }
                self.isPolling = true
                await action()
                self.isPolling = false
            }
        }
    }
}
