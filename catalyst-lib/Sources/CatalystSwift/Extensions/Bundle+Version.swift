import Foundation

public extension Bundle {
    /// Marketing version from Info.plist (e.g., "0.1.0")
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// Build number from Info.plist (e.g., "42")
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    /// Full version string (e.g., "v0.1.0 build 42")
    var fullVersion: String {
        "v\(appVersion) build \(buildNumber)"
    }
}
