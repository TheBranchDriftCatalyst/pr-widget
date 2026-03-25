import SwiftUI
import OSLog

/// A reusable log viewer for Catalyst macOS apps.
///
/// Shows log entries from the unified logging system with level filtering,
/// auto-scroll, and the ability to open Console.app for the full log.
///
/// ```swift
/// Tab("Logs", systemImage: "terminal") {
///     LogViewerView(store: logStore)
/// }
/// ```
public struct LogViewerView: View {
    @Bindable var store: LogStore
    @State private var autoScroll = true
    @State private var searchText = ""

    public init(store: LogStore) {
        self.store = store
    }

    private var displayedEntries: [LogEntry] {
        let filtered = store.filteredEntries
        guard !searchText.isEmpty else { return filtered }
        let q = searchText.lowercased()
        return filtered.filter {
            $0.message.lowercased().contains(q) || $0.category.lowercased().contains(q)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().opacity(0.3)
            logContent
        }
        .task { store.refresh() }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            // Level filter
            Picker("Level", selection: $store.filterLevel) {
                Text("All").tag(OSLogEntryLog.Level?.none)
                Text("Info+").tag(OSLogEntryLog.Level?.some(.info))
                Text("Notice+").tag(OSLogEntryLog.Level?.some(.notice))
                Text("Error+").tag(OSLogEntryLog.Level?.some(.error))
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)

            TextField("Filter...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)

            Spacer()

            Text("\(displayedEntries.count) entries")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

            Toggle("Auto-scroll", isOn: $autoScroll)
                .toggleStyle(.switch)
                .controlSize(.mini)

            Button {
                store.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh logs")

            Button {
                openConsoleApp()
            } label: {
                Image(systemName: "terminal")
            }
            .buttonStyle(.borderless)
            .help("Open in Console.app")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var logContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(displayedEntries) { entry in
                        logRow(entry)
                            .id(entry.id)
                        Divider().opacity(0.15)
                    }
                }
            }
            .onChange(of: displayedEntries.count) {
                if autoScroll, let last = displayedEntries.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
        .font(.system(size: 11, design: .monospaced))
    }

    private func logRow(_ entry: LogEntry) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(entry.date, format: .dateTime.hour().minute().second().secondFraction(.fractional(3)))
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Text(entry.levelLabel)
                .fontWeight(.bold)
                .foregroundStyle(levelColor(entry.level))
                .frame(width: 52, alignment: .leading)

            if !entry.category.isEmpty {
                Text("[\(entry.category)]")
                    .foregroundStyle(.tertiary)
            }

            Text(entry.message)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }

    private func levelColor(_ level: OSLogEntryLog.Level) -> Color {
        switch level {
        case .error, .fault: .red
        case .notice: .yellow
        case .info: .blue
        default: .secondary
        }
    }

    private func openConsoleApp() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Console.app"))
    }
}
