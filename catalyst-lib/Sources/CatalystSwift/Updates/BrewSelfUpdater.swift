import AppKit
import Foundation

/// Manages self-update via Homebrew cask for any Catalyst app.
///
/// `BrewSelfUpdater` checks for newer versions by querying `brew info --cask`
/// and comparing the tap version against the running app's
/// `CFBundleShortVersionString`. When an update is available, it can
/// launch a Terminal-based upgrade script that quits the app, runs
/// `brew upgrade --cask`, and reopens it.
///
/// ## Usage
///
/// ```swift
/// let updater = BrewSelfUpdater(caskName: "p-arr", appName: "P-Arr")
///
/// // Check for updates
/// Task { await updater.checkForUpdate() }
///
/// // Show status
/// if updater.updateAvailable {
///     print("Update: \(updater.currentVersion) -> \(updater.latestVersion!)")
/// }
///
/// // Trigger upgrade (quits app, upgrades, reopens)
/// updater.performUpdate()
/// ```
///
/// - Important: Requires Homebrew to be installed and the app to be
///   distributed via a cask in a Homebrew tap.
@MainActor @Observable
public final class BrewSelfUpdater {
    /// The Homebrew cask name (e.g., `"p-arr"`).
    public let caskName: String

    /// The application name used for process management (e.g., `"P-Arr"`).
    public let appName: String

    /// The latest version available in the Homebrew tap, or `nil` if not yet checked.
    public private(set) var latestVersion: String?

    /// Whether a version check is currently in progress.
    public private(set) var isChecking = false

    /// Whether an update is available (latest version differs from current).
    public private(set) var updateAvailable = false

    /// An error message from the last check, or `nil` if successful.
    public private(set) var error: String?

    /// The current installed version from `Bundle.main`.
    public var currentVersion: String { Bundle.main.appVersion }

    /// Creates a brew self-updater.
    /// - Parameters:
    ///   - caskName: The Homebrew cask name.
    ///   - appName: The application process name.
    public init(caskName: String, appName: String) {
        self.caskName = caskName
        self.appName = appName
    }

    /// Checks for a newer version in the Homebrew tap.
    ///
    /// Sets ``latestVersion``, ``updateAvailable``, and ``error`` based
    /// on the result. Sets ``isChecking`` to `true` during the check.
    public func checkForUpdate() async {
        isChecking = true
        error = nil
        latestVersion = nil
        updateAvailable = false
        defer { isChecking = false }

        do {
            try await refreshTap()
            let version = try await fetchLatestVersion()
            latestVersion = version
            updateAvailable = version != currentVersion
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Launches a Terminal-based upgrade script and quits the app.
    ///
    /// The script waits for the app to exit, runs `brew upgrade --cask`,
    /// reopens the app, and cleans up after itself.
    ///
    /// - Warning: This terminates the current application.
    public func performUpdate() {
        let script = """
        #!/bin/bash
        # Wait for app to quit
        while pgrep -x "\(appName)" > /dev/null; do sleep 0.5; done
        # Upgrade via brew
        brew upgrade --cask \(caskName)
        # Reopen the app
        open -a "\(appName)"
        # Clean up
        rm -f "$0"
        """

        let path = "/tmp/catalyst-update-\(caskName).sh"
        do {
            try script.write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: path
            )
        } catch {
            self.error = "Failed to write update script: \(error.localizedDescription)"
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", path]
        try? process.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }

    // MARK: - Private

    /// Refreshes the Homebrew tap so `brew info` sees the latest cask versions.
    private func refreshTap() async throws {
        let brewPath = Self.findBrewPath()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["update", "--auto-update"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    // Non-fatal: proceed with stale cache rather than blocking the check
                    continuation.resume()
                }
            }

            do {
                try process.run()
            } catch {
                // brew update failed — proceed anyway with stale cache
                continuation.resume()
            }
        }
    }

    private func fetchLatestVersion() async throws -> String {
        let brewPath = Self.findBrewPath()
        let cask = caskName

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["info", "--cask", cask, "--json=v2"]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            process.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard process.terminationStatus == 0 else {
                    continuation.resume(throwing: BrewUpdateError.caskNotFound(cask))
                    return
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    guard let casks = json?["casks"] as? [[String: Any]],
                          let first = casks.first,
                          let version = first["version"] as? String
                    else {
                        continuation.resume(throwing: BrewUpdateError.parseError)
                        return
                    }
                    continuation.resume(returning: version)
                } catch {
                    continuation.resume(throwing: BrewUpdateError.parseError)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: BrewUpdateError.brewNotFound)
            }
        }
    }

    private static func findBrewPath() -> String {
        // Apple Silicon default, then Intel default
        for path in ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"] {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return "/opt/homebrew/bin/brew"
    }
}

/// Errors that can occur during a Homebrew update check.
public enum BrewUpdateError: LocalizedError {
    /// Homebrew is not installed at the expected paths.
    case brewNotFound

    /// The specified cask was not found in any installed tap.
    case caskNotFound(String)

    /// The JSON output from `brew info` could not be parsed.
    case parseError

    public var errorDescription: String? {
        switch self {
        case .brewNotFound:
            "Homebrew not found. Install it from https://brew.sh"
        case .caskNotFound(let name):
            "Cask '\(name)' not found. Install with: brew install --cask \(name)"
        case .parseError:
            "Failed to parse brew output"
        }
    }
}
