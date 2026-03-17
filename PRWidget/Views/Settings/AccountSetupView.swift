import SwiftUI
import CatalystSwift

struct AccountSetupView: View {
    @Environment(AccountManager.self) var accountManager
    @Environment(\.dismiss) private var dismiss

    @State private var token = ""
    @State private var host = "github.com"
    @State private var hostType: GitHubHostType = .cloud
    @State private var isVerifying = false
    @State private var error: String?

    @State private var client = GitHubGraphQLClient()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ADD ACCOUNT")
                .scaledFont(size: 13, weight: .bold, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Catalyst.cyan)

            Picker("Host Type", selection: $hostType) {
                Text("GitHub.com").tag(GitHubHostType.cloud)
                Text("GitHub Enterprise").tag(GitHubHostType.enterprise)
            }
            .pickerStyle(.segmented)

            if hostType == .enterprise {
                TextField("Enterprise Host", text: $host, prompt: Text("github.company.com"))
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Personal Access Token")
                    .scaledFont(size: 13, weight: .medium)
                    .foregroundStyle(Catalyst.foreground)
                SecureField("ghp_...", text: $token)
                    .textFieldStyle(.roundedBorder)
                Text("Needs scopes: repo, read:org")
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundStyle(Catalyst.muted)
            }

            if let error {
                Text(error)
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.red)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add Account") { verifyAndAdd() }
                    .buttonStyle(.borderedProminent)
                    .tint(Catalyst.cyan)
                    .foregroundStyle(Catalyst.background)
                    .keyboardShortcut(.defaultAction)
                    .disabled(token.isEmpty || isVerifying)
            }

            if isVerifying {
                HStack {
                    ProgressView().controlSize(.small).tint(Catalyst.cyan)
                    Text("Verifying token...")
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundStyle(Catalyst.muted)
                }
            }
        }
        .padding(20)
        .frame(width: 400)
        .background(Catalyst.background)
    }

    private func verifyAndAdd() {
        isVerifying = true
        error = nil

        let endpoint: URL
        switch hostType {
        case .cloud:
            endpoint = URL(string: "https://api.github.com/graphql")!
        case .enterprise:
            guard let enterpriseURL = URL(string: "https://\(host)/api/graphql") else {
                error = "Invalid host: \(host)"
                isVerifying = false
                return
            }
            endpoint = enterpriseURL
        }

        Task {
            do {
                let response: VerifyViewerResponse = try await client.execute(
                    query: GitHubQueries.verifyViewer,
                    token: token,
                    endpoint: endpoint
                )

                try accountManager.addAccount(
                    username: response.viewer.login,
                    token: token,
                    host: host,
                    hostType: hostType
                )
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isVerifying = false
        }
    }
}
