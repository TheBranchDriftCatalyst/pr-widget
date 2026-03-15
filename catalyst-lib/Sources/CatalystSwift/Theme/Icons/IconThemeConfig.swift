import Foundation

/// Configuration for an app's icon theme system.
///
/// Defines the naming convention, available variants, and persistence key
/// used by ``IconThemeManager`` to resolve icon assets at runtime.
///
/// The default naming convention maps to asset catalog imagesets:
/// - Menu bar icons: `"MenuBarIcon-A"`, `"MenuBarIcon-B"`
/// - App icon previews: `"AppIconPreview-A"`, `"AppIconPreview-B"`
/// - Slot-based: `"{prefix}-{slot}{variant}"` e.g. `"p-arr-02a"`
public struct IconThemeConfig: Sendable {
    public let appPrefix: String
    public let variants: [IconVariant]
    public let defaultVariant: IconVariant
    public let persistenceKey: String

    public init(
        appPrefix: String,
        variants: [IconVariant] = IconVariant.allCases.map { $0 },
        defaultVariant: IconVariant = .a,
        persistenceKey: String = "Catalyst.iconVariant"
    ) {
        self.appPrefix = appPrefix
        self.variants = variants
        self.defaultVariant = defaultVariant
        self.persistenceKey = persistenceKey
    }

    /// Asset catalog name for a variant's menu bar icon imageset.
    public func menuBarImageName(variant: IconVariant) -> String {
        "MenuBarIcon-\(variant.rawValue.uppercased())"
    }

    /// Asset catalog name for a variant's app icon preview imageset.
    public func appIconPreviewName(variant: IconVariant) -> String {
        "AppIconPreview-\(variant.rawValue.uppercased())"
    }

    /// Slot-based image name: `"{prefix}-{slot}{variant}"`.
    public func imageName(slot: String, variant: IconVariant) -> String {
        "\(appPrefix)-\(slot)\(variant.rawValue)"
    }
}
