import Foundation
import Observation
import CatalystSwift

@MainActor
@Observable
final class AISettings {
    private enum Keys {
        static let ollamaEnabled = Persisted<Bool>("PArr.ai.ollamaEnabled", default: false)
        static let ollamaBaseURL = Persisted<String>("PArr.ai.ollamaBaseURL", default: "http://localhost:11434")
        static let ollamaModel = Persisted<String>("PArr.ai.ollamaModel", default: "llama3.2")
        static let openAIEnabled = Persisted<Bool>("PArr.ai.openAIEnabled", default: false)
        static let openAIModel = Persisted<String>("PArr.ai.openAIModel", default: "gpt-4o-mini")
        // Can't reference @MainActor defaultPromptTemplate/defaultResponseFormat here,
        // so we use empty string as default and fall back in init.
        static let promptTemplate = Persisted<String>("PArr.ai.promptTemplate", default: "")
        static let responseFormat = Persisted<String>("PArr.ai.responseFormat", default: "")
        static let openAIKey = PersistedSecret(service: "com.catalyst.p-arr", account: "openai-api-key")
    }

    var ollamaEnabled: Bool {
        didSet { Keys.ollamaEnabled.save(ollamaEnabled) }
    }
    var ollamaBaseURL: String {
        didSet { Keys.ollamaBaseURL.save(ollamaBaseURL) }
    }
    var selectedOllamaModel: String {
        didSet { Keys.ollamaModel.save(selectedOllamaModel) }
    }
    var openAIEnabled: Bool {
        didSet { Keys.openAIEnabled.save(openAIEnabled) }
    }
    var openAIModel: String {
        didSet { Keys.openAIModel.save(openAIModel) }
    }
    var synopsisPromptTemplate: String {
        didSet { Keys.promptTemplate.save(synopsisPromptTemplate) }
    }
    var synopsisResponseFormat: String {
        didSet { Keys.responseFormat.save(synopsisResponseFormat) }
    }

    var availableOllamaModels: [OllamaModel] = []

    static let defaultPromptTemplate = """
        Analyze this GitHub Pull Request and provide a brief synopsis with action items.

        Title: {{title}}
        Author: {{author}}
        Repository: {{repo}}
        Branch: {{headBranch}} → {{baseBranch}}
        State: {{state}}, Draft: {{isDraft}}
        Size: +{{additions}}/-{{deletions}}, {{changedFiles}} files
        Review: {{reviewDecision}}
        CI: {{ciStatus}}
        Mergeable: {{mergeable}}
        Age: {{age}}

        Description: {{description}}

        Recent comments:
        {{recentComments}}
        """

    static let defaultResponseFormat = """
        Respond in this format:
        SUMMARY: [1-2 sentence summary]
        ACTIONS: [comma-separated action items]
        URGENCY: [reason if urgent, or NONE]
        """

    var openAIKey: String {
        didSet {
            if openAIKey.isEmpty {
                Keys.openAIKey.delete()
            } else {
                Keys.openAIKey.save(openAIKey)
            }
        }
    }

    init() {
        self.ollamaEnabled = Keys.ollamaEnabled.load()
        self.ollamaBaseURL = Keys.ollamaBaseURL.load()
        self.selectedOllamaModel = Keys.ollamaModel.load()
        self.openAIEnabled = Keys.openAIEnabled.load()
        self.openAIModel = Keys.openAIModel.load()
        let loadedPrompt = Keys.promptTemplate.load()
        self.synopsisPromptTemplate = loadedPrompt.isEmpty ? Self.defaultPromptTemplate : loadedPrompt
        let loadedFormat = Keys.responseFormat.load()
        self.synopsisResponseFormat = loadedFormat.isEmpty ? Self.defaultResponseFormat : loadedFormat
        self.openAIKey = Keys.openAIKey.load() ?? ""
    }

    func refreshOllamaModels() async {
        let client = OllamaClient(baseURL: URL(string: ollamaBaseURL) ?? URL(string: "http://localhost:11434")!)
        do {
            availableOllamaModels = try await client.listModels()
        } catch {
            availableOllamaModels = []
        }
    }

    var isOllamaAvailable: Bool {
        !availableOllamaModels.isEmpty
    }
}
