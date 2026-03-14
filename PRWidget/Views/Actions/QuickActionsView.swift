import SwiftUI
import CatalystSwift

struct QuickActionsView: View {
    let pr: PullRequest
    let onApprove: () -> Void
    let onMerge: (MergeMethod) -> Void
    let onRequestChanges: (String) -> Void

    @State private var showMergeOptions = false
    @State private var showRequestChanges = false
    @State private var changeComment = ""

    var body: some View {
        HStack(spacing: 8) {
            Button {
                onApprove()
            } label: {
                Label("Approve", systemImage: "checkmark.circle")
            }
            .buttonStyle(.bordered)
            .tint(Catalyst.cyan)
            .controlSize(.small)

            Button {
                showMergeOptions = true
            } label: {
                Label("Merge", systemImage: "arrow.triangle.merge")
            }
            .buttonStyle(.bordered)
            .tint(Catalyst.magenta)
            .controlSize(.small)
            .popover(isPresented: $showMergeOptions) {
                MergeOptionsView { method in
                    showMergeOptions = false
                    onMerge(method)
                }
            }

            Button {
                showRequestChanges = true
            } label: {
                Label("Request Changes", systemImage: "exclamationmark.bubble")
            }
            .buttonStyle(.bordered)
            .tint(Catalyst.warning)
            .controlSize(.small)
            .popover(isPresented: $showRequestChanges) {
                RequestChangesPopover(comment: $changeComment) {
                    showRequestChanges = false
                    onRequestChanges(changeComment)
                    changeComment = ""
                }
            }
        }
    }
}
