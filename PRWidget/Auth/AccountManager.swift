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
        let account = GitHubAccount(
            username: username,
            host: host,
            hostType: hostType
        )
        try KeychainManager.save(token: token, for: account.id)
        accounts.append(account)
        saveAccounts()
    }

    func removeAccount(_ account: GitHubAccount) {
        try? KeychainManager.delete(for: account.id)
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
    }

    func token(for account: GitHubAccount) -> String? {
        try? KeychainManager.getToken(for: account.id)
    }

    private func saveAccounts() {
        Self.accountsKey.save(accounts)
    }
}
