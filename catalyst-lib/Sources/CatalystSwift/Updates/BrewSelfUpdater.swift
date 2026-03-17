import AppKit
import Foundation

/// Manages self-update via Homebrew cask for any Catalyst app.
@MainActor @Observable
public final class BrewSelfUpdater {
    public let caskName: String
    public let appName: String

    public private(set) var latestVersion: String?
    public private(set) var isChecking = false
    public private(set) var updateAvailable = false
    public private(set) var error: String?

    public var currentVersion: String { Bundle.main.appVersion }

    public init(caskName: String, appName: String) {
        self.caskName = caskName
        self.appName = appName
    }

    public func checkForUpdate() async {
        isChecking = true
        error = nil
        latestVersion = nil
        updateAvailable = false
        defer { isChecking = false }

        do {
            let version = try await fetchLatestVersion()
            latestVersion = version
            updateAvailable = version != currentVersion
        } catch {
            self.error = error.localizedDescription
        }
    }

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

public enum BrewUpdateError: LocalizedError {
    case brewNotFound
    case caskNotFound(String)
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
