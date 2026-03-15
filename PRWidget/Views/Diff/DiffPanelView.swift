import SwiftUI
import CatalystSwift

struct DiffPanelView: View {
    let pr: PullRequest
    @Environment(DashboardStore.self) var store
    @Environment(AccountManager.self) var accountManager

    @State private var files: [PRFileDiff] = []
    @State private var selectedPath: String?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            GlowDivider()

            if isLoading {
                loadingView
            } else if let error {
                errorView(error)
            } else if files.isEmpty {
                emptyView
            } else {
                HSplitView {
                    FileListSidebar(files: files, selectedPath: $selectedPath)

                    if let selectedPath, let file = files.first(where: { $0.path == selectedPath }) {
                        DiffContentView(file: file) { threadId, body in
                            try await replyToThread(threadId: threadId, body: body)
                        }
                    } else {
                        noSelectionView
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Catalyst.background)
        .task { await loadDiffs() }
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Text("PR #\(pr.number)")
                .scaledFont(size: 12, weight: .bold, design: .monospaced)
                .foregroundStyle(Catalyst.cyan)

            Text(pr.title)
                .scaledFont(size: 12, weight: .medium)
                .foregroundStyle(Catalyst.foreground)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Text(pr.repository.nameWithOwner)
                .scaledFont(size: 11, design: .monospaced)
                .foregroundStyle(Catalyst.muted)

            Button {
                NSWorkspace.shared.open(pr.url)
            } label: {
                Image(systemName: "arrow.up.right")
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.cyan)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard()
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .controlSize(.small)
                .tint(Catalyst.cyan)
            Text("LOADING DIFFS...")
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Catalyst.muted)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.title3)
                .foregroundStyle(Catalyst.warning)
            Text(message)
                .scaledFont(size: 12)
                .foregroundStyle(Catalyst.muted)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadDiffs() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Catalyst.cyan)
            .foregroundStyle(Catalyst.background)
            .controlSize(.small)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "doc.text")
                .scaledFont(size: 28)
                .foregroundStyle(Catalyst.subtle)
            Text("NO FILE CHANGES")
                .scaledFont(size: 12, weight: .bold, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Catalyst.muted)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noSelectionView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .scaledFont(size: 28)
                .foregroundStyle(Catalyst.subtle)
            Text("SELECT A FILE")
                .scaledFont(size: 12, weight: .bold, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Catalyst.muted)
            Text("Choose a file from the sidebar to view its diff")
                .scaledFont(size: 11)
                .foregroundStyle(Catalyst.subtle)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadDiffs() async {
        isLoading = true
        error = nil

        // Ensure detail is fetched (for review threads)
        if pr.detail == nil {
            _ = await store.fetchDetail(for: pr)
        }

        do {
            files = try await store.fetchFileDiffs(for: pr)
            if let first = files.first {
                selectedPath = first.path
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func replyToThread(threadId: String, body: String) async throws {
        guard let account = accountManager.accounts.first,
              let token = accountManager.token(for: account) else { return }

        let newComment = try await store.replyToReviewThread(
            threadId: threadId,
            body: body,
            token: token,
            endpoint: account.graphQLEndpoint
        )

        // Update local state
        for i in files.indices {
            for j in files[i].reviewThreads.indices {
                if files[i].reviewThreads[j].id == threadId {
                    files[i].reviewThreads[j].comments.append(newComment)
                }
            }
        }
    }
}
