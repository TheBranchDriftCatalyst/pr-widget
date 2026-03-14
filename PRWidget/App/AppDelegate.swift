import AppKit
import CatalystSwift
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var windowManager: WindowManager!
    private var settingsWindow: NSWindow?
    let accountManager = AccountManager()
    private(set) lazy var dashboardStore = DashboardStore(accountManager: accountManager)
    let aiSettings = AISettings()
    private(set) lazy var synopsisEngine = SynopsisEngine(aiSettings: aiSettings)
    let mentionTracker = MentionTracker()
    private let hotkeyManager = HotkeyManager()

    private enum Keys {
        static let settingsWidth = Persisted<Double>("PArr.settingsWidth", default: 600)
        static let settingsHeight = Persisted<Double>("PArr.settingsHeight", default: 620)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[PArr] applicationDidFinishLaunching called")

        // Migrate from old PRWidget prefix
        DefaultsMigration.migratePrefix(
            from: "PRWidget",
            to: "PArr",
            keys: [
                "activeFilter", "collapsedRepos", "pinnedPRIDs", "isPinned",
                "repoOrder", "windowWidth", "windowHeight", "seenMentionIDs",
                "hotkeyCombo", "accounts", "selectedLabels", "excludedLabels",
                "ai.ollamaEnabled", "ai.ollamaBaseURL", "ai.ollamaModel",
                "ai.openAIEnabled", "ai.openAIModel", "ai.promptTemplate",
                "ai.responseFormat", "settingsWidth", "settingsHeight",
            ]
        )
        // Migrate Keychain tokens
        if let data = UserDefaults.standard.data(forKey: "PArr.accounts") ?? UserDefaults.standard.data(forKey: "PRWidget.accounts"),
           let accounts = try? JSONDecoder().decode([GitHubAccount].self, from: data) {
            for account in accounts {
                DefaultsMigration.migrateKeychainService(
                    from: "com.catalyst.prwidget",
                    to: "com.catalyst.p-arr",
                    account: account.id.uuidString
                )
            }
        }
        DefaultsMigration.migrateKeychainService(
            from: "com.catalyst.prwidget",
            to: "com.catalyst.p-arr",
            account: "00000000-0000-0000-0000-000000000001"
        )

        // Close the dummy SwiftUI WindowGroup window
        for window in NSApplication.shared.windows {
            window.close()
        }

        setupStatusItem()
        NSLog("[PArr] Status item set up, button: \(statusItem.button != nil)")
        setupWindowManager()
        NSLog("[PArr] Window manager set up")
        setupGlobalHotkey()

        if accountManager.hasAccounts {
            Task { await dashboardStore.refresh() }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "arrow.trianglehead.pull", accessibilityDescription: "PR Widget")
            image?.isTemplate = true
            button.image = image
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }

    private var badgeView: NSView?

    func updateBadge() {
        guard let button = statusItem?.button else { return }

        // Remove existing badge
        badgeView?.removeFromSuperview()
        badgeView = nil

        let count = mentionTracker.unreadMentionCount
        guard count > 0 else { return }

        let badgeSize: CGFloat = 14
        let badge = NSView(frame: NSRect(
            x: button.bounds.width - badgeSize + 2,
            y: button.bounds.height - badgeSize + 2,
            width: badgeSize,
            height: badgeSize
        ))
        badge.wantsLayer = true
        badge.layer?.backgroundColor = NSColor(red: 1.0, green: 0.161, blue: 0.459, alpha: 1.0).cgColor
        badge.layer?.cornerRadius = badgeSize / 2

        let label = NSTextField(labelWithString: count > 9 ? "9+" : "\(count)")
        label.font = NSFont.monospacedSystemFont(ofSize: 8, weight: .bold)
        label.textColor = NSColor.white
        label.alignment = .center
        label.frame = badge.bounds
        badge.addSubview(label)

        button.addSubview(badge)
        badgeView = badge
    }

    private func setupWindowManager() {
        let contentView = DashboardView(
            onOpenSettings: { [weak self] in
                self?.openSettings()
            },
            onTogglePin: { [weak self] in
                guard let self else { return }
                self.dashboardStore.isPinned.toggle()
                self.windowManager.setPinned(self.dashboardStore.isPinned)
            }
        )
        .environment(dashboardStore)
        .environment(accountManager)
        .environment(aiSettings)
        .environment(synopsisEngine)
        .environment(mentionTracker)

        windowManager = WindowManager(contentView: contentView)
    }

    private func setupGlobalHotkey() {
        hotkeyManager.register { [weak self] in
            self?.togglePanel()
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showStatusMenu()
        } else {
            togglePanel()
        }
    }

    private func togglePanel() {
        windowManager.toggle(relativeTo: statusItem)
    }

    private func showStatusMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit P-Arr", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Clear menu so left-click goes back to toggle behavior
        statusItem.menu = nil
    }

    @objc func openSettings() {
        if let settingsWindow, settingsWindow.isVisible {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environment(accountManager)
            .environment(aiSettings)
            .environment(hotkeyManager)

        let w = Keys.settingsWidth.load()
        let h = Keys.settingsHeight.load()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "P-Arr Settings"
        window.minSize = NSSize(width: 520, height: 500)
        window.maxSize = NSSize(width: 900, height: 900)
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { @Sendable [weak window] _ in
            MainActor.assumeIsolated {
                guard let window else { return }
                Keys.settingsWidth.save(window.frame.width)
                Keys.settingsHeight.save(window.frame.height)
            }
        }

        settingsWindow = window
    }
}
