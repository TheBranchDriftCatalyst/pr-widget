import SwiftUI
import CatalystSwift

struct MergeOptionsView: View {
    let onSelect: (MergeMethod) -> Void

    @State private var hoveredMethod: MergeMethod?

    var body: some View {
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
                    onSelect(method)
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

    private func icon(for method: MergeMethod) -> String {
        switch method {
        case .squash: "arrow.down.right.and.arrow.up.left"
        case .merge: "arrow.triangle.merge"
        case .rebase: "arrow.uturn.up"
        }
    }
}
