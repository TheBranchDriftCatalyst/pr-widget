import AppKit
import SwiftUI

extension Notification.Name {
    public static let iconVariantDidChange = Notification.Name("Catalyst.iconVariantDidChange")
}

/// Manages the active icon variant and provides image loading helpers.
@Observable
@MainActor
public final class IconThemeManager {
    public let config: IconThemeConfig
    private let storage: Persisted<String>

    public var activeVariant: IconVariant {
        didSet {
            guard oldValue != activeVariant else { return }
            storage.save(activeVariant.rawValue)
            NotificationCenter.default.post(name: .iconVariantDidChange, object: self)
        }
    }

    public init(config: IconThemeConfig) {
        self.config = config
        self.storage = Persisted<String>(config.persistenceKey, default: config.defaultVariant.rawValue)
        let raw = storage.load()
        self.activeVariant = IconVariant(rawValue: raw) ?? config.defaultVariant
    }

    // MARK: - Image Loading

    /// Load the menu bar icon for the active variant as a template `NSImage`.
    public func menuBarIcon() -> NSImage? {
        menuBarIcon(for: activeVariant)
    }

    /// Load the menu bar icon for a specific variant.
    public func menuBarIcon(for variant: IconVariant) -> NSImage? {
        let name = config.menuBarImageName(variant: variant)
        guard let image = NSImage(named: name) else { return nil }
        image.isTemplate = true
        return image
    }

    /// Load the app icon preview for the active variant.
    public func appIconPreview() -> NSImage? {
        appIconPreview(for: activeVariant)
    }

    /// Load the app icon preview for a specific variant.
    public func appIconPreview(for variant: IconVariant) -> NSImage? {
        NSImage(named: config.appIconPreviewName(variant: variant))
    }

    /// Load an icon by slot name for the active variant.
    public func icon(slot: String) -> NSImage? {
        icon(slot: slot, variant: activeVariant)
    }

    /// Load an icon for a specific slot and variant.
    public func icon(slot: String, variant: IconVariant) -> NSImage? {
        NSImage(named: config.imageName(slot: slot, variant: variant))
    }

    /// SwiftUI `Image` for a given slot and the active variant.
    public func image(slot: String) -> Image {
        Image(config.imageName(slot: slot, variant: activeVariant))
    }
}
