import SwiftUI

/// Shared label context menu content for PR rows.
/// Shows available labels with add/remove/recycle actions.
struct LabelContextMenu: View {
    let pr: PullRequest
    let store: DashboardStore
    let accountManager: AccountManager

    var body: some View {
        let repoLabels = store.repoLabels(for: pr)
        let existingNames = Set(pr.labels.map(\.name))

        if repoLabels.isEmpty {
            Text("No labels available")
        } else {
            Menu("Labels") {
                ForEach(repoLabels) { label in
                    let hasLabel = existingNames.contains(label.name)
                    if hasLabel {
                        Button {
                            performAction(.remove, label: label)
                        } label: {
                            Label(label.name, systemImage: "checkmark")
                        }
                        Button {
                            performAction(.recycle, label: label)
                        } label: {
                            Label("Re-apply \(label.name)", systemImage: "arrow.triangle.2.circlepath")
                        }
                    } else {
                        Button(label.name) {
                            performAction(.add, label: label)
                        }
                    }
                }
            }
        }
    }

    private enum LabelAction { case add, remove, recycle }

    private func performAction(_ action: LabelAction, label: PRLabel) {
        guard let account = store.account(for: pr),
              let token = accountManager.token(for: account) else { return }
        let endpoint = account.graphQLEndpoint
        let actionHandler = ActionHandler()

        Task {
            do {
                let updatedLabels: [PRLabel]
                switch action {
                case .add:
                    updatedLabels = try await actionHandler.addLabel(to: pr, labelNodeId: label.nodeId, token: token, endpoint: endpoint)
                case .remove:
                    updatedLabels = try await actionHandler.removeLabel(from: pr, labelNodeId: label.nodeId, token: token, endpoint: endpoint)
                case .recycle:
                    updatedLabels = try await actionHandler.recycleLabel(on: pr, labelNodeId: label.nodeId, token: token, endpoint: endpoint)
                }
                store.updateLabels(for: pr.id, labels: updatedLabels)
            } catch {
                // Label state will correct on next refresh
            }
        }
    }
}
