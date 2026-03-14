import SwiftUI
import CatalystSwift

struct AccountsSettingsView: View {
    @Environment(AccountManager.self) var accountManager
    @State private var showingAddAccount = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            List {
                ForEach(accountManager.accounts) { account in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(Catalyst.cyan)
                        VStack(alignment: .leading) {
                            Text(account.username)
                                .fontWeight(.medium)
                                .foregroundStyle(Catalyst.foreground)
                            Text(account.host)
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundStyle(Catalyst.muted)
                        }
                        Spacer()
                        Button("Remove", systemImage: "trash", role: .destructive) {
                            accountManager.removeAccount(account)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .foregroundStyle(Catalyst.red)
                    }
                }
            }
            .frame(minHeight: 150)

            HStack {
                Spacer()
                Button("Add Account...") { showingAddAccount = true }
                    .buttonStyle(.borderedProminent)
                    .tint(Catalyst.cyan)
                    .foregroundStyle(Catalyst.background)
                    .controlSize(.small)
            }
        }
        .padding()
        .sheet(isPresented: $showingAddAccount) {
            AccountSetupView()
                .environment(accountManager)
        }
    }
}
