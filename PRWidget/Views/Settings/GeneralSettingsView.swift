import Carbon
import SwiftUI
import CatalystSwift

struct GeneralSettingsView: View {
    @Environment(HotkeyManager.self) var hotkeyManager
    @Environment(IconThemeManager.self) var iconManager
    @Environment(PollingScheduler.self) var pollingScheduler
    @AppStorage("PArr.ui.textScale") private var textScale: Double = 1.0
    @AppStorage("PArr.mergeEnabled") private var mergeEnabled: Bool = true
    @State private var isRecording = false
    @State private var pendingCombo: HotkeyCombo?

    private static let intervalOptions: [(String, TimeInterval)] = [
        ("10s", 10),
        ("30s", 30),
        ("1 min", 60),
        ("2 min", 120),
        ("5 min", 300),
        ("10 min", 600),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon theme section
            IconThemePickerView(manager: iconManager)

            // Polling / refresh section
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "AUTO-REFRESH")

                @Bindable var scheduler = pollingScheduler

                Toggle(isOn: Binding(
                    get: { scheduler.isEnabled },
                    set: { scheduler.isEnabled = $0 }
                )) {
                    Text("Auto-refresh dashboard")
                        .scaledFont(size: 12, design: .monospaced)
                        .foregroundStyle(Catalyst.foreground)
                }
                .toggleStyle(.switch)
                .tint(Catalyst.cyan)

                if scheduler.isEnabled {
                    HStack(spacing: 10) {
                        Text("Refresh every")
                            .scaledFont(size: 12, design: .monospaced)
                            .foregroundStyle(Catalyst.foreground)

                        Picker("", selection: Binding(
                            get: { scheduler.interval },
                            set: { scheduler.interval = $0 }
                        )) {
                            ForEach(Self.intervalOptions, id: \.1) { label, value in
                                Text(label).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)

                        Spacer()
                    }

                    HStack(spacing: 4) {
                        Text("GitHub allows ~5,000 points/hr. Each refresh ≈ 2 points. At 10s you use ~720 pts/hr (14%).")
                            .scaledFont(size: 10)
                            .foregroundStyle(Catalyst.subtle)

                        Link(destination: URL(string: "https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api")!) {
                            Text("Learn more")
                                .scaledFont(size: 10)
                                .foregroundStyle(Catalyst.cyan)
                        }
                    }
                }
            }
            .padding(10)
            .glassCard()

            // Hotkey section
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "KEYBOARD SHORTCUT")

                HStack(spacing: 10) {
                    Text("Toggle Panel")
                        .scaledFont(size: 12, design: .monospaced)
                        .foregroundStyle(Catalyst.foreground)

                    Spacer()

                    HotkeyRecorderView(
                        combo: pendingCombo ?? hotkeyManager.currentCombo,
                        isRecording: $isRecording,
                        onRecord: { combo in
                            pendingCombo = combo
                            hotkeyManager.currentCombo = combo
                            isRecording = false
                        }
                    )

                    Button("Reset") {
                        hotkeyManager.currentCombo = .default
                        pendingCombo = nil
                    }
                    .controlSize(.mini)
                    .buttonStyle(.bordered)
                    .disabled(hotkeyManager.currentCombo == .default)
                }
            }
            .padding(10)
            .glassCard()

            // Text scale section
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "TEXT SCALE")

                UIScaleSlider(scale: Binding(
                    get: { CGFloat(textScale) },
                    set: { textScale = Double($0) }
                ))
            }
            .padding(10)
            .glassCard()

            // Safety section
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "SAFETY")

                Toggle(isOn: $mergeEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Allow Merge Actions")
                            .scaledFont(size: 12, design: .monospaced)
                            .foregroundStyle(Catalyst.foreground)
                        Text("Disable to prevent accidental merges from the dashboard")
                            .scaledFont(size: 10)
                            .foregroundStyle(Catalyst.subtle)
                    }
                }
                .toggleStyle(.switch)
                .tint(Catalyst.cyan)
            }
            .padding(10)
            .glassCard()

            Spacer()
        }
        .padding()
    }
}

// MARK: - Hotkey Recorder

struct HotkeyRecorderView: View {
    let combo: HotkeyCombo
    @Binding var isRecording: Bool
    let onRecord: (HotkeyCombo) -> Void

    var body: some View {
        Button {
            isRecording.toggle()
        } label: {
            Text(isRecording ? "Press shortcut..." : combo.displayString)
                .scaledFont(size: 11, weight: .medium, design: .monospaced)
                .foregroundStyle(isRecording ? Catalyst.warning : Catalyst.cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isRecording ? Catalyst.warning.opacity(0.15) : Catalyst.cyan.opacity(0.1),
                    in: .rect(cornerRadius: Catalyst.radiusMD)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Catalyst.radiusMD)
                        .strokeBorder(isRecording ? Catalyst.warning : Catalyst.cyan.opacity(0.3), lineWidth: 1)
                )
                .if(isRecording) { $0.neonGlow(Catalyst.warning, radius: 6) }
        }
        .buttonStyle(.plain)
        .onKeyPress { keyPress in
            guard isRecording else { return .ignored }

            // Convert SwiftUI KeyPress to NSEvent-like modifiers
            var carbonMods: UInt32 = 0
            if keyPress.modifiers.contains(.command) { carbonMods |= UInt32(cmdKey) }
            if keyPress.modifiers.contains(.shift) { carbonMods |= UInt32(shiftKey) }
            if keyPress.modifiers.contains(.option) { carbonMods |= UInt32(optionKey) }
            if keyPress.modifiers.contains(.control) { carbonMods |= UInt32(controlKey) }

            guard carbonMods != 0 else { return .ignored }

            // Map character to key code (approximate)
            let keyCode = carbonKeyCode(from: keyPress.characters)
            let newCombo = HotkeyCombo(keyCode: keyCode, modifiers: carbonMods)
            onRecord(newCombo)
            return .handled
        }
        .focusable(isRecording)
    }

    private func carbonKeyCode(from characters: String) -> UInt32 {
        let charMap: [Character: UInt32] = [
            "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
            "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
            "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
            "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
            "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35,
            "l": 37, "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43,
            "/": 44, "n": 45, "m": 46, ".": 47, " ": 49, "`": 50,
        ]
        if let first = characters.lowercased().first, let code = charMap[first] {
            return code
        }
        return 35 // Default to P
    }
}
