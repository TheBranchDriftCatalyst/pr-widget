import Foundation

public extension Bundle {
    /// The marketing version string from `Info.plist` (`CFBundleShortVersionString`).
    ///
    /// Returns `"0.0.0"` if the key is missing.
    ///
    /// ```swift
    /// let version = Bundle.main.appVersion // e.g., "0.4.0"
    /// ```
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// The build number from `Info.plist` (`CFBundleVersion`).
    ///
    /// Returns `"0"` if the key is missing.
    ///
    /// ```swift
    /// let build = Bundle.main.buildNumber // e.g., "42"
    /// ```
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    /// A formatted version string combining marketing version and build number.
    ///
    /// ```swift
    /// let full = Bundle.main.fullVersion // e.g., "v0.4.0 build 42"
    /// ```
    var fullVersion: String {
        "v\(appVersion) build \(buildNumber)"
    }
}
