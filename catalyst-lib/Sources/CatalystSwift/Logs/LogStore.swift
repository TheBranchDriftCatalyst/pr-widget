import Foundation
import OSLog
import Observation

/// A log store that reads entries from the unified logging system for the current process.
///
/// Use this to display recent log messages in a settings/debug panel.
///
/// ```swift
/// let logStore = LogStore(subsystem: "com.catalyst.p-arr")
/// LogViewerView(store: logStore)
/// ```
@MainActor
@Observable
public final class LogStore {
    public private(set) var entries: [LogEntry] = []
    public private(set) var isLoading = false
    public let subsystem: String
    public var filterLevel: OSLogEntryLog.Level?

    /// Maximum number of entries to keep in memory.
    public var maxEntries: Int = 500

    /// Time window to fetch logs from (seconds). Default 10 minutes.
    public var timeWindow: TimeInterval = 600

    public var filteredEntries: [LogEntry] {
        guard let filterLevel else { return entries }
        return entries.filter { $0.level.rawValue >= filterLevel.rawValue }
    }

    public init(subsystem: String = "") {
        self.subsystem = subsystem
    }

    /// Fetches log entries off the main thread and updates the store.
    public func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let subsystem = self.subsystem
        let maxEntries = self.maxEntries
        let timeWindow = self.timeWindow

        let fetched = await Task.detached(priority: .utility) {
            Self.fetchEntries(subsystem: subsystem, maxEntries: maxEntries, timeWindow: timeWindow)
        }.value

        entries = fetched
    }

    /// Synchronous fetch on a background thread. No @MainActor, no XPC on main thread.
    private nonisolated static func fetchEntries(
        subsystem: String,
        maxEntries: Int,
        timeWindow: TimeInterval
    ) -> [LogEntry] {
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(timeIntervalSinceEnd: -timeWindow)
            let predicate: NSPredicate? = subsystem.isEmpty
                ? nil
                : NSPredicate(format: "subsystem == %@", subsystem)
            let rawEntries = try store.getEntries(at: position, matching: predicate)

            var result: [LogEntry] = []
            result.reserveCapacity(maxEntries)

            for entry in rawEntries {
                guard let logEntry = entry as? OSLogEntryLog else { continue }
                result.append(LogEntry(
                    date: logEntry.date,
                    level: logEntry.level,
                    message: logEntry.composedMessage,
                    category: logEntry.category,
                    subsystem: logEntry.subsystem
                ))
                if result.count >= maxEntries { break }
            }

            return result
        } catch {
            return []
        }
    }
}

public struct LogEntry: Identifiable, Sendable {
    public let id = UUID()
    public let date: Date
    public let level: OSLogEntryLog.Level
    public let message: String
    public let category: String
    public let subsystem: String

    public var levelLabel: String {
        switch level {
        case .debug: "DEBUG"
        case .info: "INFO"
        case .notice: "NOTICE"
        case .error: "ERROR"
        case .fault: "FAULT"
        default: "LOG"
        }
    }

    public var levelColor: String {
        switch level {
        case .error, .fault: "red"
        case .notice: "yellow"
        case .info: "blue"
        default: "muted"
        }
    }
}
