import SwiftUI

public extension Color {
    /// Creates a color from a 6-character hex string.
    ///
    /// The leading `#` is optional. Returns `nil` for invalid input.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let color = Color(hex: "#ff6ec7") // Catalyst pink
    /// let same = Color(hex: "ff6ec7")   // Also works
    /// let bad = Color(hex: "nope")      // nil
    /// ```
    ///
    /// - Parameter hex: A 6-character hex color string, with or without `#`.
    /// - Returns: A `Color` instance, or `nil` if the string is invalid.
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))

        guard hex.count == 6,
              let int = UInt64(hex, radix: 16) else {
            return nil
        }

        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
