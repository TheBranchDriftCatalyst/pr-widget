import SwiftUI
import CatalystSwift

struct MergeOptionsView: View {
    let prTitle: String
    let baseRefName: String
    let onSelect: (MergeMethod) -> Void

    @State private var hoveredMethod: MergeMethod?
    @State private var selectedMethod: MergeMethod?

    var body: some View {
        if let method = selectedMethod {
            confirmationView(method: method)
        } else {
            methodSelectionView
        }
    }

    // MARK: - Method Selection

    private var methodSelectionView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MERGE METHOD")
                .font(.caption)
                .fontWeight(.bold)
                .fontDesign(.monospaced)
                .tracking(1)
                .foregroundStyle(Catalyst.magenta)
                .padding(.bottom, 4)

            ForEach(MergeMethod.allCases, id: \.self) { method in
                Button {
                    selectedMethod = method
                } label: {
                    HStack {
                        Image(systemName: icon(for: method))
                            .foregroundStyle(Catalyst.cyan)
                            .frame(width: 16)
                        Text(method.displayName)
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundStyle(Catalyst.foreground)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: Catalyst.cornerRadius)
                        .fill(hoveredMethod == method ? Catalyst.surface : Color.clear)
                )
                .onHover { isHovering in
                    hoveredMethod = isHovering ? method : nil
                }
            }
        }
        .padding(12)
        .frame(width: 220)
        .background(Catalyst.card)
    }

    // MARK: - Confirmation

    private func confirmationView(method: MergeMethod) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CONFIRM MERGE")
                .font(.caption)
                .fontWeight(.bold)
                .fontDesign(.monospaced)
                .tracking(1)
                .foregroundStyle(Catalyst.red)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("Method:")
                        .foregroundStyle(Catalyst.muted)
                    Text(method.displayName)
                        .foregroundStyle(Catalyst.foreground)
                }

                HStack(spacing: 4) {
                    Text("Into:")
                        .foregroundStyle(Catalyst.muted)
                    Text(baseRefName)
                        .foregroundStyle(Catalyst.magenta)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Catalyst.magenta.opacity(0.1), in: .rect(cornerRadius: 3))
                }

                Text(prTitle)
                    .foregroundStyle(Catalyst.foreground)
                    .lineLimit(2)
            }
            .scaledFont(size: 11, design: .monospaced)

            HStack(spacing: 8) {
                Button {
                    selectedMethod = nil
                } label: {
                    Text("Cancel")
                        .scaledFont(size: 11, weight: .medium, design: .monospaced)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(Catalyst.muted)
                .controlSize(.small)

                Button {
                    onSelect(method)
                } label: {
                    Text("Confirm Merge")
                        .scaledFont(size: 11, weight: .medium, design: .monospaced)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Catalyst.red)
                .controlSize(.small)
            }
        }
        .padding(12)
        .frame(width: 260)
        .background(Catalyst.card)
    }

    private func icon(for method: MergeMethod) -> String {
        switch method {
        case .squash: "arrow.down.right.and.arrow.up.left"
        case .merge: "arrow.triangle.merge"
        case .rebase: "arrow.uturn.up"
        }
    }
}
