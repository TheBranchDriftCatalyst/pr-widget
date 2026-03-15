import Carbon
import SwiftUI
import CatalystSwift

struct GeneralSettingsView: View {
    @Environment(HotkeyManager.self) var hotkeyManager
    @AppStorage("PArr.ui.textScale") private var textScale: Double = 1.0
    @State private var isRecording = false
    @State private var pendingCombo: HotkeyCombo?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

            // About
            VStack(alignment: .leading, spacing: 4) {
                SectionHeader(title: "ABOUT")

                Text("P-Arr — Catalyst DevSpace")
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundStyle(Catalyst.foreground)
                Text("macOS floating dashboard for GitHub PR management")
                    .scaledFont(size: 10)
                    .foregroundStyle(Catalyst.subtle)
                Text(Bundle.main.fullVersion)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.muted)
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
