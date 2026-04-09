import SwiftUI

/// A reusable diagnostics panel for Catalyst macOS apps.
///
/// Shows live resource usage (memory, threads, uptime) and provides
/// CPU sample capture via `/usr/bin/sample`.
///
/// ```swift
/// Tab("Diagnostics", systemImage: "gauge.with.dots.needle.33percent") {
///     DiagnosticsView(monitor: resourceMonitor)
/// }
/// ```
public struct DiagnosticsView: View {
    @Bindable var monitor: ResourceMonitor

    public init(monitor: ResourceMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                resourceUsageSection
                profilingSection
                Spacer()
            }
            .padding()
        }
        .onAppear { monitor.startMonitoring() }
        .onDisappear { monitor.stopMonitoring() }
    }

    // MARK: - Resource Usage

    private var resourceUsageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("RESOURCE USAGE")

            statRow("Physical Memory", formatBytes(monitor.snapshot.physicalMemory), icon: "memorychip")
            memoryBar
            Text("\(memoryPercent) of \(formatBytes(monitor.snapshot.systemTotalMemory)) system memory")
                .scaledFont(size: 9, design: .monospaced)
                .foregroundStyle(Catalyst.subtle)

            GlowDivider()

            statRow("Virtual Memory", formatBytes(monitor.snapshot.virtualMemory), icon: "square.stack.3d.up")
            statRow("Threads", "\(monitor.snapshot.threadCount)", icon: "cpu")
            statRow("PID", "\(monitor.snapshot.pid)", icon: "number")
            statRow("Uptime", formatUptime(monitor.snapshot.uptime), icon: "clock")

            HStack(spacing: 4) {
                Spacer()
                Circle()
                    .fill(Catalyst.cyan)
                    .frame(width: 5, height: 5)
                    .shadow(color: Catalyst.cyan.opacity(0.5), radius: 3)
                Text("LIVE")
                    .scaledFont(size: 8, weight: .bold, design: .monospaced)
                    .tracking(1)
                    .foregroundStyle(Catalyst.cyan)
            }
        }
        .padding(10)
        .glassCard()
    }

    private var memoryBar: some View {
        let fraction = monitor.snapshot.systemTotalMemory > 0
            ? Double(monitor.snapshot.physicalMemory) / Double(monitor.snapshot.systemTotalMemory)
            : 0

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Catalyst.surface)
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(fraction: fraction).opacity(0.7))
                    .frame(width: geo.size.width * min(CGFloat(fraction), 1.0))
                    .shadow(color: barColor(fraction: fraction).opacity(0.4), radius: 3)
            }
        }
        .frame(height: 4)
    }

    private func barColor(fraction: Double) -> Color {
        if fraction > 0.8 { return Catalyst.red }
        if fraction > 0.6 { return Catalyst.yellow }
        return Catalyst.cyan
    }

    private var memoryPercent: String {
        guard monitor.snapshot.systemTotalMemory > 0 else { return "0%" }
        let pct = Double(monitor.snapshot.physicalMemory) / Double(monitor.snapshot.systemTotalMemory) * 100
        return String(format: "%.1f%%", pct)
    }

    // MARK: - Profiling

    private var profilingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("PERFORMANCE PROFILING")

            Text("Capture a CPU sample to diagnose hangs and performance issues. Output saved to Desktop.")
                .scaledFont(size: 10)
                .foregroundStyle(Catalyst.muted)

            HStack(spacing: 10) {
                Text("Duration")
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundStyle(Catalyst.muted)

                Picker("Duration", selection: $monitor.selectedDuration) {
                    Text("5s").tag(5)
                    Text("10s").tag(10)
                    Text("30s").tag(30)
                    Text("60s").tag(60)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
            }

            if monitor.isSampling {
                samplingProgress
            } else {
                Button {
                    Task { await monitor.captureSample() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.path.ecg")
                        Text("Capture Sample")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Catalyst.cyan)
                .foregroundStyle(Catalyst.background)
                .controlSize(.regular)
            }

            if let result = monitor.lastSampleResult {
                resultView(result)
            }
        }
        .padding(10)
        .glassCard()
    }

    private var samplingProgress: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(
                value: Double(monitor.selectedDuration - monitor.samplingSecondsRemaining),
                total: Double(max(monitor.selectedDuration, 1))
            )
            .tint(Catalyst.cyan)

            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Sampling... \(monitor.samplingSecondsRemaining)s remaining")
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundStyle(Catalyst.muted)
            }
        }
    }

    @ViewBuilder
    private func resultView(_ result: SampleResult) -> some View {
        switch result {
        case .success(let url):
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Catalyst.cyan)
                    .shadow(color: Catalyst.cyan.opacity(0.4), radius: 3)

                Text(url.lastPathComponent)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.foreground)
                    .lineLimit(1)

                Spacer()

                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                .controlSize(.small)
                .buttonStyle(.bordered)
            }

        case .failure(let message):
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Catalyst.red)
                Text(message)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.red)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Helpers

    private func statRow(_ label: String, _ value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .scaledFont(size: 11)
                .foregroundStyle(Catalyst.subtle)
                .frame(width: 20)

            Text(label)
                .scaledFont(size: 11, design: .monospaced)
                .foregroundStyle(Catalyst.muted)
                .frame(width: 120, alignment: .leading)

            Spacer()

            Text(value)
                .scaledFont(size: 12, weight: .bold, design: .monospaced)
                .foregroundStyle(Catalyst.cyan)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .tracking(1)
            .foregroundStyle(Catalyst.muted)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 { return "\(h)h \(m)m \(s)s" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }
}
