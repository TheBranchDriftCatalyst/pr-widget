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
    ///
    /// Does NOT set `isTemplate` — caller can set it if the source images
    /// are monochrome/alpha-based. Full-color artwork should remain non-template.
    public func menuBarIcon(for variant: IconVariant) -> NSImage? {
        let name = config.menuBarImageName(variant: variant)
        guard let image = loadImage(named: name) else { return nil }
        // Resize to standard menu bar height (18pt, auto @2x)
        image.size = NSSize(width: 18, height: 18)
        return image
    }

    /// Load the app icon preview for the active variant.
    public func appIconPreview() -> NSImage? {
        appIconPreview(for: activeVariant)
    }

    /// Load the app icon preview for a specific variant.
    public func appIconPreview(for variant: IconVariant) -> NSImage? {
        loadImage(named: config.appIconPreviewName(variant: variant))
    }

    /// Load an icon by slot name for the active variant.
    public func icon(slot: String) -> NSImage? {
        icon(slot: slot, variant: activeVariant)
    }

    /// Load an icon for a specific slot and variant.
    public func icon(slot: String, variant: IconVariant) -> NSImage? {
        loadImage(named: config.imageName(slot: slot, variant: variant))
    }

    /// SwiftUI `Image` for a given slot and the active variant.
    public func image(slot: String) -> Image {
        Image(config.imageName(slot: slot, variant: activeVariant), bundle: config.bundle)
    }

    // MARK: - Private

    private func loadImage(named name: String) -> NSImage? {
        // Try compiled asset catalog first
        if let image = config.bundle.image(forResource: name) {
            return image
        }
        // Try main bundle
        if let image = NSImage(named: name) {
            return image
        }
        // Fallback: load from raw xcassets in SPM resource bundle
        return loadFromRawAssets(named: name)
    }

    /// SPM debug builds copy xcassets as raw directories — load PNGs directly.
    private func loadFromRawAssets(named name: String) -> NSImage? {
        let bundleURL = config.bundle.bundleURL

        // Try as imageset: Assets.xcassets/{name}.imageset/
        let imagesetURL = bundleURL
            .appendingPathComponent("Assets.xcassets")
            .appendingPathComponent("\(name).imageset")

        if let contents = try? FileManager.default.contentsOfDirectory(atPath: imagesetURL.path) {
            // Pick the @2x image if available, otherwise first PNG
            let preferred = contents.first(where: { $0.contains("@2x") && $0.hasSuffix(".png") })
                ?? contents.first(where: { $0.hasSuffix(".png") })
            if let filename = preferred {
                return NSImage(contentsOf: imagesetURL.appendingPathComponent(filename))
            }
        }

        // Try as appiconset: Assets.xcassets/{name}.appiconset/ (use 128x128@2x)
        let appiconsetURL = bundleURL
            .appendingPathComponent("Assets.xcassets")
            .appendingPathComponent("\(name).appiconset")

        if let contents = try? FileManager.default.contentsOfDirectory(atPath: appiconsetURL.path) {
            let preferred = contents.first(where: { $0.contains("128x128@2x") && $0.hasSuffix(".png") })
                ?? contents.first(where: { $0.contains("256x256") && $0.hasSuffix(".png") })
                ?? contents.first(where: { $0.hasSuffix(".png") })
            if let filename = preferred {
                return NSImage(contentsOf: appiconsetURL.appendingPathComponent(filename))
            }
        }

        return nil
    }
}
