import Foundation
import Observation

@MainActor
@Observable
final class SynopsisEngine {
    private let openAIClient = OpenAIClient()
    private var cache: [String: AISynopsis] = [:]

    let aiSettings: AISettings

    init(aiSettings: AISettings) {
        self.aiSettings = aiSettings
    }

    func generateSynopsis(for pr: PullRequest, detail: PRDetail) async -> AISynopsis {
        let cacheKey = "\(pr.id)_\(pr.updatedAt.timeIntervalSince1970)"
        if let cached = cache[cacheKey] {
            return cached
        }

        let prompt = buildPrompt(for: pr, detail: detail)

        // Try Ollama first
        if aiSettings.ollamaEnabled {
            if let result = await tryOllama(prompt: prompt) {
                let synopsis = parseAIResponse(result, provider: .ollama)
                cache[cacheKey] = synopsis
                return synopsis
            }
        }

        // Try OpenAI
        if aiSettings.openAIEnabled {
            if let result = await tryOpenAI(prompt: prompt) {
                let synopsis = parseAIResponse(result, provider: .openAI)
                cache[cacheKey] = synopsis
                return synopsis
            }
        }

        // Algorithmic fallback
        let synopsis = AlgorithmicSynopsis.generate(for: pr, detail: detail)
        cache[cacheKey] = synopsis
        return synopsis
    }

    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Private

    private func tryOllama(prompt: String) async -> String? {
        do {
            let client = OllamaClient(baseURL: URL(string: aiSettings.ollamaBaseURL) ?? URL(string: "http://localhost:11434")!)
            guard await client.isAvailable() else { return nil }
            return try await client.generate(
                model: aiSettings.selectedOllamaModel,
                prompt: prompt
            )
        } catch {
            return nil
        }
    }

    private func tryOpenAI(prompt: String) async -> String? {
        let apiKey = aiSettings.openAIKey
        guard !apiKey.isEmpty else { return nil }
        do {
            return try await openAIClient.generate(
                apiKey: apiKey,
                model: aiSettings.openAIModel,
                prompt: prompt
            )
        } catch {
            return nil
        }
    }

    private func buildPrompt(for pr: PullRequest, detail: PRDetail) -> String {
        let recentComments = detail.comments.suffix(5)
        let commentsText = recentComments.map { "- \($0.author.login): \(String($0.body.prefix(150)))" }.joined(separator: "\n")

        let variables: [String: String] = [
            "title": pr.title,
            "author": pr.author.login,
            "repo": pr.repository.nameWithOwner,
            "headBranch": pr.headRefName,
            "baseBranch": pr.baseRefName,
            "state": pr.state.rawValue,
            "isDraft": String(pr.isDraft),
            "additions": String(pr.additions),
            "deletions": String(pr.deletions),
            "changedFiles": String(detail.changedFiles),
            "reviewDecision": pr.reviewDecision?.rawValue ?? "none",
            "ciStatus": pr.statusCheckRollup.rawValue,
            "mergeable": pr.mergeable.rawValue,
            "age": pr.ageText,
            "description": String(detail.bodyText.prefix(500)),
            "recentComments": commentsText,
        ]

        var result = aiSettings.synopsisPromptTemplate
        for (key, value) in variables {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }

        result += "\n\n"
        var format = aiSettings.synopsisResponseFormat
        for (key, value) in variables {
            format = format.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        result += format

        return result
    }

    private func parseAIResponse(_ response: String, provider: SynopsisProvider) -> AISynopsis {
        var summary = response
        var actionItems: [String] = []
        var urgencyReason: String?

        let lines = response.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("SUMMARY:") {
                summary = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("ACTIONS:") {
                let actionsStr = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                actionItems = actionsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else if trimmed.hasPrefix("URGENCY:") {
                let urgency = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                if urgency.uppercased() != "NONE" && !urgency.isEmpty {
                    urgencyReason = urgency
                }
            }
        }

        return AISynopsis(
            summary: summary,
            actionItems: actionItems,
            urgencyReason: urgencyReason,
            generatedAt: .now,
            provider: provider
        )
    }
}
