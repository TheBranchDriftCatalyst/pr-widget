import SwiftUI
import CatalystSwift

struct SettingsView: View {
    @Environment(AccountManager.self) var accountManager
    @Environment(AISettings.self) var aiSettings
    @Environment(HotkeyManager.self) var hotkeyManager
    @Environment(BrewSelfUpdater.self) var brewUpdater
    @Environment(LogStore.self) var logStore

    var body: some View {
        TabView {
            Tab("Accounts", systemImage: "person.2") {
                AccountsSettingsView()
                    .environment(accountManager)
            }

            Tab("AI", systemImage: "brain") {
                AISettingsView()
                    .environment(aiSettings)
            }

            Tab("Prompt", systemImage: "text.bubble") {
                PromptSettingsView()
                    .environment(aiSettings)
            }

            Tab("General", systemImage: "gearshape") {
                GeneralSettingsView()
                    .environment(hotkeyManager)
            }

            Tab("Updates", systemImage: "arrow.down.circle") {
                BrewUpdateView(updater: brewUpdater)
            }

            Tab("Changelog", systemImage: "doc.text.magnifyingglass") {
                ChangelogView(releases: ChangelogParser.fromBundle())
            }

            Tab("Logs", systemImage: "terminal") {
                LogViewerView(store: logStore)
            }

            Tab("Help", systemImage: "questionmark.circle") {
                HelpSettingsView(tips: HelpTip.all)
            }

            Tab("About", systemImage: "info.circle") {
                AboutSettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .frame(minWidth: 520, idealWidth: 600, maxWidth: 900, minHeight: 500, idealHeight: 620, maxHeight: 900)
        .background(Catalyst.background)
        .foregroundStyle(Catalyst.foreground)
    }
}
