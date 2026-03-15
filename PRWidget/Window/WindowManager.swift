import AppKit
import SwiftUI
import CatalystSwift

@MainActor
final class WindowManager {
    private enum Keys {
        static let windowWidth = Persisted<Double>("PArr.windowWidth", default: 420)
        static let windowHeight = Persisted<Double>("PArr.windowHeight", default: 560)
        static let isPinned = Persisted<Bool>("PArr.isPinned", default: true)
    }

    private let panel: FloatingPanel
    private(set) var isPinned: Bool

    init<Content: View>(contentView: Content) {
        let width = CGFloat(Keys.windowWidth.load())
        let height = CGFloat(Keys.windowHeight.load())

        isPinned = Keys.isPinned.load()
        let frame = NSRect(x: 0, y: 0, width: width, height: height)
        panel = FloatingPanel(contentRect: frame)

        panel.level = isPinned ? .statusBar : .normal
        panel.minSize = NSSize(width: 380, height: 300)
        panel.maxSize = NSSize(width: 600, height: 900)

        let hostingView = NSHostingView(
            rootView: contentView.clipShape(.rect(cornerRadius: Catalyst.cornerRadius))
        )
        hostingView.layer?.cornerRadius = Catalyst.cornerRadius
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.borderWidth = 1
        hostingView.layer?.borderColor = NSColor(red: 0.153, green: 0.153, blue: 0.165, alpha: 0.6).cgColor

        panel.contentView = hostingView

        // Neon glow shadow — dual-layer cyan + magenta
        panel.hasShadow = true
        hostingView.layer?.shadowColor = NSColor(red: 0.0, green: 0.988, blue: 0.839, alpha: 0.3).cgColor
        hostingView.layer?.shadowRadius = 30
        hostingView.layer?.shadowOffset = CGSize(width: 0, height: -2)
        hostingView.layer?.shadowOpacity = 1

        // Subtle pulsing glow
        startGlowPulse(layer: hostingView.layer)

        panel.onResignKey = { [weak self] in
            guard let self, !self.isPinned else { return }
            self.hide()
        }

        panel.onEscape = { [weak self] in
            self?.hide()
        }
    }

    private func startGlowPulse(layer: CALayer?) {
        guard let layer else { return }
        // Initial pulse animation
        let pulseDown = CABasicAnimation(keyPath: "shadowOpacity")
        pulseDown.fromValue = Float(0.2)
        pulseDown.toValue = Float(0.35)
        pulseDown.duration = 3.0
        pulseDown.autoreverses = true
        pulseDown.repeatCount = .infinity
        pulseDown.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(pulseDown, forKey: "glowPulse")
    }

    var isVisible: Bool { panel.isVisible }
    var panelFrame: NSRect { panel.frame }

    func toggle(relativeTo statusItem: NSStatusItem?) {
        if panel.isVisible {
            hide()
        } else {
            show(relativeTo: statusItem)
        }
    }

    func show(relativeTo statusItem: NSStatusItem?) {
        positionBelow(statusItem)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        let size = panel.frame.size
        Keys.windowWidth.save(size.width)
        Keys.windowHeight.save(size.height)
        let panelRef = panel
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panelRef.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor in
                panelRef.orderOut(nil)
            }
        })
    }

    func setPinned(_ pinned: Bool) {
        isPinned = pinned
        panel.level = pinned ? .statusBar : .normal
        Keys.isPinned.save(pinned)
    }

    private func positionBelow(_ statusItem: NSStatusItem?) {
        guard let button = statusItem?.button,
              let buttonWindow = button.window else { return }

        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let currentSize = panel.frame.size

        // Center horizontally under the status item, but clamp to screen
        var x = buttonFrame.midX - currentSize.width / 2
        let y = buttonFrame.minY - currentSize.height - 4

        // Clamp to screen bounds
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let screenFrame = screen.visibleFrame
            let maxX = screenFrame.maxX - currentSize.width - 8
            let minX = screenFrame.minX + 8
            x = min(max(x, minX), maxX)
        }

        panel.setFrame(NSRect(x: x, y: y, width: currentSize.width, height: currentSize.height), display: true)
    }
}
