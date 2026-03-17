import SwiftUI
import CatalystSwift

struct AISettingsView: View {
    @Environment(AISettings.self) var aiSettings

    var body: some View {
        @Bindable var s = aiSettings
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Provider fallback chain
                VStack(alignment: .leading, spacing: 4) {
                    SectionHeader(title: "PROVIDER FALLBACK CHAIN")

                    HStack(spacing: 4) {
                        providerTag("Ollama", enabled: aiSettings.ollamaEnabled)
                        Image(systemName: "arrow.right")
                            .scaledFont(size: 8)
                            .foregroundStyle(Catalyst.subtle)
                        providerTag("OpenAI", enabled: aiSettings.openAIEnabled)
                        Image(systemName: "arrow.right")
                            .scaledFont(size: 8)
                            .foregroundStyle(Catalyst.subtle)
                        providerTag("Algorithmic", enabled: true)
                    }
                }

                // Ollama section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SectionHeader(title: "OLLAMA", accentColor: Catalyst.foreground)

                        Spacer()

                        NeonDot(color: aiSettings.isOllamaAvailable ? Catalyst.success : Catalyst.red)

                        Toggle("", isOn: $s.ollamaEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                    }

                    if aiSettings.ollamaEnabled {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Base URL")
                                    .scaledFont(size: 10, design: .monospaced)
                                    .foregroundStyle(Catalyst.muted)
                                    .frame(width: 60, alignment: .trailing)
                                TextField("http://localhost:11434", text: $s.ollamaBaseURL)
                                    .textFieldStyle(.roundedBorder)
                                    .scaledFont(size: 10, design: .monospaced)
                                    .controlSize(.small)
                            }

                            HStack {
                                Text("Model")
                                    .scaledFont(size: 10, design: .monospaced)
                                    .foregroundStyle(Catalyst.muted)
                                    .frame(width: 60, alignment: .trailing)

                                if aiSettings.availableOllamaModels.isEmpty {
                                    TextField("llama3.2", text: $s.selectedOllamaModel)
                                        .textFieldStyle(.roundedBorder)
                                        .scaledFont(size: 10, design: .monospaced)
                                        .controlSize(.small)
                                } else {
                                    Picker("", selection: $s.selectedOllamaModel) {
                                        ForEach(aiSettings.availableOllamaModels, id: \.name) { model in
                                            Text(model.name).tag(model.name)
                                        }
                                    }
                                    .controlSize(.small)
                                }

                                Button("Refresh") {
                                    Task { await aiSettings.refreshOllamaModels() }
                                }
                                .controlSize(.mini)
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding(10)
                .glassCard()

                // OpenAI section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SectionHeader(title: "OPENAI", accentColor: Catalyst.foreground)

                        Spacer()

                        Toggle("", isOn: $s.openAIEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                    }

                    if aiSettings.openAIEnabled {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("API Key")
                                    .scaledFont(size: 10, design: .monospaced)
                                    .foregroundStyle(Catalyst.muted)
                                    .frame(width: 60, alignment: .trailing)
                                SecureField("sk-...", text: $s.openAIKey)
                                    .textFieldStyle(.roundedBorder)
                                    .scaledFont(size: 10, design: .monospaced)
                                    .controlSize(.small)
                            }

                            HStack {
                                Text("Model")
                                    .scaledFont(size: 10, design: .monospaced)
                                    .foregroundStyle(Catalyst.muted)
                                    .frame(width: 60, alignment: .trailing)
                                TextField("gpt-4o-mini", text: $s.openAIModel)
                                    .textFieldStyle(.roundedBorder)
                                    .scaledFont(size: 10, design: .monospaced)
                                    .controlSize(.small)
                            }
                        }
                    }
                }
                .padding(10)
                .glassCard()
            }
            .padding()
        }
    }

    private func providerTag(_ name: String, enabled: Bool) -> some View {
        Text(name.uppercased())
            .scaledFont(size: 9, weight: .semibold, design: .monospaced)
            .foregroundStyle(enabled ? Catalyst.cyan : Catalyst.subtle)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(enabled ? Catalyst.cyan.opacity(0.15) : Catalyst.surface, in: .rect(cornerRadius: Catalyst.radiusSM))
    }
}
