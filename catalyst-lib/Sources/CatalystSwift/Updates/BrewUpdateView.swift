import SwiftUI

/// Reusable Settings view for Homebrew cask self-update.
public struct BrewUpdateView: View {
    @Bindable var updater: BrewSelfUpdater

    public init(updater: BrewSelfUpdater) {
        self.updater = updater
    }

    public var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon + version
            VStack(spacing: 8) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 48))
                    .foregroundStyle(Catalyst.cyan)

                Text("v\(updater.currentVersion)")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(Catalyst.foreground)

                Text("Installed via Homebrew")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Catalyst.muted)
            }

            // Status area
            VStack(spacing: 12) {
                if updater.isChecking {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking for updates...")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Catalyst.muted)
                    }
                } else if let error = updater.error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Catalyst.warning)
                } else if updater.updateAvailable, let latest = updater.latestVersion {
                    VStack(spacing: 6) {
                        Label("Update available", systemImage: "arrow.down.circle.fill")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Catalyst.cyan)

                        Text("v\(updater.currentVersion)  \u{2192}  v\(latest)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Catalyst.muted)
                    }
                } else if updater.latestVersion != nil {
                    Label("Up to date", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
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
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
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
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
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
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Catalyst.subtle)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
