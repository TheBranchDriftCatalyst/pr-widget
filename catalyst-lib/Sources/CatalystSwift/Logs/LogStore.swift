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
    public let subsystem: String
    public var filterLevel: OSLogEntryLog.Level?

    public var filteredEntries: [LogEntry] {
        guard let filterLevel else { return entries }
        return entries.filter { $0.level.rawValue >= filterLevel.rawValue }
    }

    public init(subsystem: String = "") {
        self.subsystem = subsystem
    }

    public func refresh() {
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(timeIntervalSinceEnd: -3600) // last hour
            let predicate: NSPredicate? = subsystem.isEmpty
                ? nil
                : NSPredicate(format: "subsystem == %@", subsystem)
            let rawEntries = try store.getEntries(at: position, matching: predicate)

            entries = rawEntries.compactMap { entry -> LogEntry? in
                guard let logEntry = entry as? OSLogEntryLog else { return nil }
                return LogEntry(
                    date: logEntry.date,
                    level: logEntry.level,
                    message: logEntry.composedMessage,
                    category: logEntry.category,
                    subsystem: logEntry.subsystem
                )
            }
        } catch {
            // If OSLogStore isn't available, fall back to empty
            entries = []
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
