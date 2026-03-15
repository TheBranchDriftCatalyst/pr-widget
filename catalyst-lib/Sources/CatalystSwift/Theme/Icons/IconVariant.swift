import Foundation

/// Represents an icon theme variant (e.g., different visual styles).
public enum IconVariant: String, Codable, CaseIterable, Identifiable, Sendable {
    case a, b

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .a: "Variant A"
        case .b: "Variant B"
        }
    }
}
