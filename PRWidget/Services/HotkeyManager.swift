import AppKit
import Carbon
import CatalystSwift
import Observation

struct HotkeyCombo: Codable, Sendable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let `default` = HotkeyCombo(
        keyCode: 35, // 'P' key
        modifiers: UInt32(cmdKey | shiftKey | optionKey)
    )

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("\u{2303}") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        parts.append(Self.keyName(for: keyCode))
        return parts.joined()
    }

    static func keyName(for keyCode: UInt32) -> String {
        let keyNames: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
            44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space",
            50: "`", 51: "Delete", 53: "Escape",
        ]
        return keyNames[keyCode] ?? "Key \(keyCode)"
    }

    static func from(event: NSEvent) -> HotkeyCombo? {
        var carbonMods: UInt32 = 0
        let flags = event.modifierFlags
        if flags.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        if flags.contains(.option) { carbonMods |= UInt32(optionKey) }
        if flags.contains(.control) { carbonMods |= UInt32(controlKey) }

        // Require at least one modifier
        guard carbonMods != 0 else { return nil }

        return HotkeyCombo(keyCode: UInt32(event.keyCode), modifiers: carbonMods)
    }
}

@MainActor
@Observable
final class HotkeyManager {
    private var eventHandler: EventHandlerRef?
    private var hotkeyRef: EventHotKeyRef?
    private var callback: (() -> Void)?

    private static let comboKey = PersistedCodable<HotkeyCombo>("PArr.hotkeyCombo", default: .default)

    var currentCombo: HotkeyCombo {
        didSet {
            Self.comboKey.save(currentCombo)
            if callback != nil {
                reregister()
            }
        }
    }

    private static let hotkeyID = EventHotKeyID(signature: 0x5052_5764, id: 1) // "PRWd"

    init() {
        self.currentCombo = Self.comboKey.load()
    }

    func register(callback: @escaping () -> Void) {
        self.callback = callback
        reregister()
    }

    private func reregister() {
        unregister()

        let id = Self.hotkeyID

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            Task { @MainActor in
                manager.callback?()
            }
            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, selfPtr, &eventHandler)
        RegisterEventHotKey(currentCombo.keyCode, currentCombo.modifiers, id, GetApplicationEventTarget(), 0, &hotkeyRef)
    }

    func unregister() {
        if let hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}
