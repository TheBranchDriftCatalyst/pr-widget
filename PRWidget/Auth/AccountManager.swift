import Foundation
import Observation
import CatalystSwift

@MainActor
@Observable
final class AccountManager {
    private static let accountsKey = PersistedCodable<[GitHubAccount]>("PArr.accounts", default: [])

    private(set) var accounts: [GitHubAccount] = []

    var hasAccounts: Bool { !accounts.isEmpty }

    init() {
        self.accounts = Self.accountsKey.load()
    }

    func addAccount(username: String, token: String, host: String = "github.com", hostType: GitHubHostType = .cloud) throws {
        NSLog("[PArr] Adding account '%@' on %@ (%@)", username, host, hostType == .cloud ? "cloud" : "enterprise")
        let account = GitHubAccount(
            username: username,
            host: host,
            hostType: hostType
        )
        try KeychainManager.save(token: token, for: account.id)
        accounts.append(account)
        saveAccounts()
        NSLog("[PArr] ✓ Account '%@' added — %d account(s) total", username, accounts.count)
    }

    func removeAccount(_ account: GitHubAccount) {
        NSLog("[PArr] Removing account '%@'", account.username)
        try? KeychainManager.delete(for: account.id)
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
        NSLog("[PArr] ✓ Account '%@' removed — %d account(s) remaining", account.username, accounts.count)
    }

    func token(for account: GitHubAccount) -> String? {
        try? KeychainManager.getToken(for: account.id)
    }

    private func saveAccounts() {
        Self.accountsKey.save(accounts)
    }
}
