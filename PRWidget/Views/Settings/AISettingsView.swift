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
                    Text("PROVIDER FALLBACK CHAIN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(Catalyst.muted)

                    HStack(spacing: 4) {
                        providerTag("Ollama", enabled: aiSettings.ollamaEnabled)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                            .foregroundStyle(Catalyst.subtle)
                        providerTag("OpenAI", enabled: aiSettings.openAIEnabled)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                            .foregroundStyle(Catalyst.subtle)
                        providerTag("Algorithmic", enabled: true)
                    }
                }

                // Ollama section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("OLLAMA")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(Catalyst.foreground)

                        Spacer()

                        Circle()
                            .fill(aiSettings.isOllamaAvailable ? Catalyst.success : Catalyst.red)
                            .frame(width: 6, height: 6)
                            .shadow(color: (aiSettings.isOllamaAvailable ? Catalyst.success : Catalyst.red).opacity(0.5), radius: 3)

                        Toggle("", isOn: $s.ollamaEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                    }

                    if aiSettings.ollamaEnabled {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Base URL")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Catalyst.muted)
                                    .frame(width: 60, alignment: .trailing)
                                TextField("http://localhost:11434", text: $s.ollamaBaseURL)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 10, design: .monospaced))
                                    .controlSize(.small)
                            }

                            HStack {
                                Text("Model")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Catalyst.muted)
                                    .frame(width: 60, alignment: .trailing)

                                if aiSettings.availableOllamaModels.isEmpty {
                                    TextField("llama3.2", text: $s.selectedOllamaModel)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 10, design: .monospaced))
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
                        Text("OPENAI")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(Catalyst.foreground)

                        Spacer()

                        Toggle("", isOn: $s.openAIEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                    }

                    if aiSettings.openAIEnabled {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("API Key")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Catalyst.muted)
                                    .frame(width: 60, alignment: .trailing)
                                SecureField("sk-...", text: $s.openAIKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 10, design: .monospaced))
                                    .controlSize(.small)
                            }

                            HStack {
                                Text("Model")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Catalyst.muted)
                                    .frame(width: 60, alignment: .trailing)
                                TextField("gpt-4o-mini", text: $s.openAIModel)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 10, design: .monospaced))
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
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(enabled ? Catalyst.cyan : Catalyst.subtle)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(enabled ? Catalyst.cyan.opacity(0.15) : Catalyst.surface, in: .rect(cornerRadius: 3))
    }
}
