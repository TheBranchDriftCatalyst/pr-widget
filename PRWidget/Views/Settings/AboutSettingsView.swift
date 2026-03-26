import SwiftUI
import CatalystSwift

struct AboutSettingsView: View {
    @State private var currentIndex = 0

    private let icons: [(name: String, file: String, caption: String)] = [
        ("Classic", "p-arr-00a", "The OG — treasure map vibes"),
        ("Synthwave", "p-arr-00b", "Neon skull city"),
        ("Wooden", "p-arr-01a", "Tavern sign energy"),
        ("Cyberpunk", "p-arr-01b", "Grid runner edition"),
        ("Minimal", "p-arr-02b", "Electric bones"),
    ]

    private func loadIcon(_ filename: String) -> NSImage? {
        guard let url = Bundle.module.url(forResource: filename, withExtension: "png", subdirectory: "Icons") else { return nil }
        return NSImage(contentsOf: url)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroSection
                galleryCarousel
                creditsSection
            }
            .padding()
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        HStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: Catalyst.cyan.opacity(0.3), radius: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text("P-Arr")
                    .scaledFont(size: 22, weight: .bold, design: .monospaced)
                    .foregroundStyle(Catalyst.cyan)

                Text("Floating GitHub PR Dashboard")
                    .scaledFont(size: 12)
                    .foregroundStyle(Catalyst.foreground)

                Text(Bundle.main.fullVersion)
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundStyle(Catalyst.muted)

                Text("Catalyst DevSpace")
                    .scaledFont(size: 10)
                    .foregroundStyle(Catalyst.subtle)
            }

            Spacer()
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Gallery Carousel

    private var galleryCarousel: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "ICON GALLERY")

            let icon = icons[currentIndex]

            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) {
                            currentIndex = (currentIndex - 1 + icons.count) % icons.count
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .scaledFont(size: 16, weight: .semibold)
                            .foregroundStyle(Catalyst.cyan)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if let nsImage = loadIcon(icon.file) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(.rect(cornerRadius: Catalyst.radiusMD))
                            .shadow(color: Catalyst.cyan.opacity(0.3), radius: 8)
                            .id(icon.file)
                            .transition(.opacity)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeOut(duration: 0.25)) {
                            currentIndex = (currentIndex + 1) % icons.count
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .scaledFont(size: 16, weight: .semibold)
                            .foregroundStyle(Catalyst.cyan)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 6) {
                    Text(icon.name)
                        .scaledFont(size: 13, weight: .semibold, design: .monospaced)
                        .foregroundStyle(Catalyst.cyan)

                    Text(icon.caption)
                        .scaledFont(size: 10)
                        .foregroundStyle(Catalyst.subtle)

                    HStack(spacing: 6) {
                        ForEach(icons.indices, id: \.self) { i in
                            Circle()
                                .fill(i == currentIndex ? Catalyst.cyan : Catalyst.muted)
                                .frame(width: 6, height: 6)
                                .shadow(
                                    color: i == currentIndex ? Catalyst.cyan.opacity(0.5) : .clear,
                                    radius: i == currentIndex ? 3 : 0
                                )
                        }
                    }
                }
            }
            .padding(14)
            .glassCard()
        }
    }

    // MARK: - Credits

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "CREDITS")

            VStack(alignment: .leading, spacing: 6) {
                creditRow(label: "Built with", value: "Swift 6 + SwiftUI")
                creditRow(label: "Platform", value: "macOS 15+")
                creditRow(label: "API", value: "GitHub GraphQL v4")
                creditRow(label: "License", value: "MIT")
            }
        }
        .padding(10)
        .glassCard()
    }

    private func creditRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .scaledFont(size: 10, design: .monospaced)
                .foregroundStyle(Catalyst.subtle)
                .frame(width: 80, alignment: .trailing)

            Text(value)
                .scaledFont(size: 11, weight: .medium, design: .monospaced)
                .foregroundStyle(Catalyst.foreground)
        }
    }
}
