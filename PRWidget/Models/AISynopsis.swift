import Foundation

enum SynopsisProvider: String, Sendable {
    case ollama = "Ollama"
    case openAI = "OpenAI"
    case algorithmic = "Algorithmic"
}

struct AISynopsis: Sendable {
    let summary: String
    let actionItems: [String]
    let urgencyReason: String?
    let generatedAt: Date
    let provider: SynopsisProvider
}
