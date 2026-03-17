import SwiftUI

/// A settings panel for Homebrew cask self-update.
///
/// Displays the current installed version, update status, and action buttons.
/// Pairs with ``BrewSelfUpdater`` to check for and trigger updates.
///
/// ## Usage
///
/// ```swift
/// struct UpdateSettingsTab: View {
///     let updater: BrewSelfUpdater
///
///     var body: some View {
///         BrewUpdateView(updater: updater)
///     }
/// }
/// ```
public struct BrewUpdateView: View {
    /// The updater instance to bind to.
    @Bindable var updater: BrewSelfUpdater

    /// Creates a brew update view.
    /// - Parameter updater: The ``BrewSelfUpdater`` instance.
    public init(updater: BrewSelfUpdater) {
        self.updater = updater
    }

    public var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon + version
            VStack(spacing: 8) {
                Image(systemName: "shippingbox")
                    .scaledFont(size: 48)
                    .foregroundStyle(Catalyst.cyan)

                Text("v\(updater.currentVersion)")
                    .scaledFont(size: 24, weight: .bold, design: .monospaced)
                    .foregroundStyle(Catalyst.foreground)

                Text("Installed via Homebrew")
                    .scaledFont(size: 12, design: .monospaced)
                    .foregroundStyle(Catalyst.muted)
            }

            // Status area
            VStack(spacing: 12) {
                if updater.isChecking {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking for updates...")
                            .scaledFont(size: 12, design: .monospaced)
                            .foregroundStyle(Catalyst.muted)
                    }
                } else if let error = updater.error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .scaledFont(size: 12, design: .monospaced)
                        .foregroundStyle(Catalyst.warning)
                } else if updater.updateAvailable, let latest = updater.latestVersion {
                    VStack(spacing: 6) {
                        Label("Update available", systemImage: "arrow.down.circle.fill")
                            .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                            .foregroundStyle(Catalyst.cyan)

                        Text("v\(updater.currentVersion)  \u{2192}  v\(latest)")
                            .scaledFont(size: 12, design: .monospaced)
                            .foregroundStyle(Catalyst.muted)
                    }
                } else if updater.latestVersion != nil {
                    Label("Up to date", systemImage: "checkmark.circle.fill")
                        .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                        .foregroundStyle(Catalyst.success)
                }
            }
            .frame(minHeight: 40)

            // Action buttons
            VStack(spacing: 10) {
                if updater.updateAvailable {
                    Button {
                        updater.performUpdate()
                    } label: {
                        Label("Update to v\(updater.latestVersion ?? "")", systemImage: "arrow.down.circle")
                            .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                            .frame(maxWidth: 260)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Catalyst.cyan)
                    .controlSize(.large)
                }

                Button {
                    Task { await updater.checkForUpdate() }
                } label: {
                    Label(
                        updater.latestVersion == nil ? "Check for Update" : "Check Again",
                        systemImage: "arrow.clockwise"
                    )
                    .scaledFont(size: 12, weight: .medium, design: .monospaced)
                    .frame(maxWidth: 260)
                }
                .buttonStyle(.bordered)
                .tint(Catalyst.muted)
                .controlSize(.regular)
                .disabled(updater.isChecking)
            }

            Spacer()

            // Hint
            Text("brew upgrade --cask \(updater.caskName)")
                .scaledFont(size: 10, design: .monospaced)
                .foregroundStyle(Catalyst.subtle)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
