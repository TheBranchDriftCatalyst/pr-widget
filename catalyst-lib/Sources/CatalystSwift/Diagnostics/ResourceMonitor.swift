import Darwin
import Foundation
import Observation

/// Live resource usage monitor for Catalyst macOS apps.
///
/// Provides periodic snapshots of memory, threads, and process info via Mach APIs,
/// plus the ability to capture CPU samples via `/usr/bin/sample`.
///
/// ```swift
/// let monitor = ResourceMonitor(appName: "PArr")
/// DiagnosticsView(monitor: monitor)
/// ```
@MainActor
@Observable
public final class ResourceMonitor {
    public private(set) var snapshot = ResourceSnapshot()
    public private(set) var isMonitoring = false
    public private(set) var isSampling = false
    public private(set) var samplingSecondsRemaining = 0
    public private(set) var lastSampleResult: SampleResult?
    public var selectedDuration: Int = 10

    public let appName: String
    private let launchDate = Date()
    private var monitoringTask: Task<Void, Never>?

    public init(appName: String) {
        self.appName = appName
    }

    // MARK: - Live Monitoring

    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        snapshot = fetchStats()
        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self, !Task.isCancelled else { break }
                self.snapshot = self.fetchStats()
            }
        }
    }

    public func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
    }

    // MARK: - Mach Stats

    private func fetchStats() -> ResourceSnapshot {
        var snap = ResourceSnapshot()
        snap.pid = ProcessInfo.processInfo.processIdentifier
        snap.uptime = Date().timeIntervalSince(launchDate)
        snap.systemTotalMemory = ProcessInfo.processInfo.physicalMemory

        // Physical + virtual memory via TASK_VM_INFO
        var vmInfo = task_vm_info_data_t()
        var vmCount = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size
        )
        let vmResult = withUnsafeMutablePointer(to: &vmInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &vmCount)
            }
        }
        if vmResult == KERN_SUCCESS {
            snap.physicalMemory = UInt64(vmInfo.phys_footprint)
            snap.virtualMemory = vmInfo.virtual_size
        }

        // Thread count via task_threads
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        let threadResult = task_threads(mach_task_self_, &threadList, &threadCount)
        if threadResult == KERN_SUCCESS {
            snap.threadCount = Int(threadCount)
            if let threadList {
                vm_deallocate(
                    mach_task_self_,
                    vm_address_t(bitPattern: threadList),
                    vm_size_t(Int(threadCount) * MemoryLayout<thread_act_t>.size)
                )
            }
        }

        return snap
    }

    // MARK: - Sample Capture

    public func captureSample() async {
        let duration = selectedDuration
        let pid = ProcessInfo.processInfo.processIdentifier
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(appName.lowercased())-sample-\(timestamp).txt"
        let desktopURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
            .appendingPathComponent(filename)

        isSampling = true
        samplingSecondsRemaining = duration
        lastSampleResult = nil

        // Countdown task for UI feedback
        let countdownTask = Task { [weak self] in
            for remaining in stride(from: duration, through: 0, by: -1) {
                guard !Task.isCancelled else { break }
                self?.samplingSecondsRemaining = remaining
                if remaining > 0 {
                    try? await Task.sleep(for: .seconds(1))
                }
            }
        }

        do {
            let url = try await runSample(pid: pid, duration: duration, outputURL: desktopURL)
            lastSampleResult = .success(url)
        } catch {
            lastSampleResult = .failure(error.localizedDescription)
        }

        countdownTask.cancel()
        samplingSecondsRemaining = 0
        isSampling = false
    }

    private func runSample(pid: Int32, duration: Int, outputURL: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/sample")
            process.arguments = ["\(pid)", "\(duration)"]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            let path = outputURL.path
            process.terminationHandler = { proc in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard proc.terminationStatus == 0 else {
                    continuation.resume(throwing: SampleError.failed(proc.terminationStatus))
                    return
                }
                do {
                    try data.write(to: URL(fileURLWithPath: path))
                    continuation.resume(returning: URL(fileURLWithPath: path))
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Data Types

public struct ResourceSnapshot: Sendable {
    public var physicalMemory: UInt64 = 0
    public var virtualMemory: UInt64 = 0
    public var threadCount: Int = 0
    public var pid: Int32 = 0
    public var uptime: TimeInterval = 0
    public var systemTotalMemory: UInt64 = 0
}

public enum SampleResult: Sendable {
    case success(URL)
    case failure(String)
}

public enum SampleError: LocalizedError {
    case failed(Int32)

    public var errorDescription: String? {
        switch self {
        case .failed(let code): "sample command exited with code \(code)"
        }
    }
}
