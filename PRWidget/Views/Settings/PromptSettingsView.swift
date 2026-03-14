import SwiftUI
import CatalystSwift

struct PromptSettingsView: View {
    @Environment(AISettings.self) var aiSettings

    var body: some View {
        @Bindable var s = aiSettings
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Prompt Template
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("PROMPT TEMPLATE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(Catalyst.foreground)
                        Spacer()
                        Button("Reset") {
                            aiSettings.synopsisPromptTemplate = AISettings.defaultPromptTemplate
                            aiSettings.synopsisResponseFormat = AISettings.defaultResponseFormat
                        }
                        .controlSize(.mini)
                        .buttonStyle(.bordered)
                    }

                    Text("Use {{variable}} syntax for interpolation")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Catalyst.muted)

                    TextEditor(text: $s.synopsisPromptTemplate)
                        .font(.system(size: 10, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 160)
                        .padding(6)
                        .background(Catalyst.surface.opacity(0.5))
                        .clipShape(.rect(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Catalyst.subtle.opacity(0.3)))
                }
                .padding(10)
                .glassCard()

                // Response Format
                VStack(alignment: .leading, spacing: 8) {
                    Text("RESPONSE FORMAT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(Catalyst.foreground)

                    TextEditor(text: $s.synopsisResponseFormat)
                        .font(.system(size: 10, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 80)
                        .padding(6)
                        .background(Catalyst.surface.opacity(0.5))
                        .clipShape(.rect(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Catalyst.subtle.opacity(0.3)))
                }
                .padding(10)
                .glassCard()

                // Available Variables
                VStack(alignment: .leading, spacing: 8) {
                    Text("AVAILABLE VARIABLES")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(Catalyst.foreground)

                    let variables: [(String, String)] = [
                        ("{{title}}", "PR title"),
                        ("{{author}}", "Author login"),
                        ("{{repo}}", "owner/repo"),
                        ("{{headBranch}}", "Source branch"),
                        ("{{baseBranch}}", "Target branch"),
                        ("{{state}}", "OPEN, CLOSED, MERGED"),
                        ("{{isDraft}}", "true/false"),
                        ("{{additions}}", "Lines added"),
                        ("{{deletions}}", "Lines removed"),
                        ("{{changedFiles}}", "Files changed count"),
                        ("{{reviewDecision}}", "APPROVED, CHANGES_REQUESTED, etc."),
                        ("{{ciStatus}}", "SUCCESS, FAILURE, PENDING"),
                        ("{{mergeable}}", "MERGEABLE, CONFLICTING, UNKNOWN"),
                        ("{{age}}", "Human-readable age (e.g. 3d)"),
                        ("{{description}}", "First 500 chars of PR body"),
                        ("{{recentComments}}", "Last 5 comments"),
                    ]

                    ForEach(variables, id: \.0) { variable, description in
                        HStack(spacing: 8) {
                            Text(variable)
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Catalyst.cyan)
                                .frame(width: 130, alignment: .leading)
                            Text(description)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Catalyst.muted)
                            Spacer()
                        }
                    }
                }
                .padding(10)
                .glassCard()
            }
            .padding()
        }
    }
}
