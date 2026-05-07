import SwiftUI
import CatalystSwift

/// Renders GitHub-flavored markdown to SwiftUI views. Supports paragraphs,
/// fenced code blocks, headings, bullet/numbered lists, and blockquotes.
/// Inline formatting (bold, italic, links, inline code) is handled by
/// `AttributedString(markdown:)`.
struct MarkdownText: View {
    let text: String
    var fontSize: CGFloat = 12
    var foregroundColor: Color = Catalyst.muted

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(MarkdownParser.parse(text).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            inlineText(text)
                .font(.system(size: headingSize(for: level), weight: .bold))
                .foregroundStyle(Catalyst.foreground)

        case .paragraph(let text):
            inlineText(text)
                .scaledFont(size: fontSize)
                .foregroundStyle(foregroundColor)
                .fixedSize(horizontal: false, vertical: true)

        case .codeBlock(let lang, let code):
            VStack(alignment: .leading, spacing: 2) {
                if let lang, !lang.isEmpty {
                    Text(lang)
                        .scaledFont(size: 9, weight: .medium, design: .monospaced)
                        .foregroundStyle(Catalyst.subtle)
                }
                Text(code)
                    .scaledFont(size: fontSize - 1, design: .monospaced)
                    .foregroundStyle(Catalyst.foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Catalyst.background.opacity(0.6), in: .rect(cornerRadius: Catalyst.radiusSM))
                    .overlay(
                        RoundedRectangle(cornerRadius: Catalyst.radiusSM)
                            .strokeBorder(Catalyst.subtle.opacity(0.3), lineWidth: 0.5)
                    )
            }

        case .blockquote(let text):
            inlineText(text)
                .scaledFont(size: fontSize, weight: .regular, design: .default)
                .foregroundStyle(Catalyst.subtle)
                .italic()
                .padding(.leading, 8)
                .overlay(
                    Rectangle()
                        .fill(Catalyst.subtle.opacity(0.4))
                        .frame(width: 2),
                    alignment: .leading
                )
                .fixedSize(horizontal: false, vertical: true)

        case .list(let items, let ordered):
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .top, spacing: 6) {
                        Text(ordered ? "\(idx + 1)." : "•")
                            .scaledFont(size: fontSize, design: .monospaced)
                            .foregroundStyle(Catalyst.cyan)
                            .frame(minWidth: 14, alignment: .trailing)
                        inlineText(item)
                            .scaledFont(size: fontSize)
                            .foregroundStyle(foregroundColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func headingSize(for level: Int) -> CGFloat {
        switch level {
        case 1: fontSize + 5
        case 2: fontSize + 3
        case 3: fontSize + 2
        default: fontSize + 1
        }
    }

    private func inlineText(_ raw: String) -> Text {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if let attr = try? AttributedString(
            markdown: trimmed,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attr)
        }
        return Text(trimmed)
    }
}

enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case codeBlock(language: String?, code: String)
    case blockquote(String)
    case list(items: [String], ordered: Bool)
}

enum MarkdownParser {
    static func parse(_ source: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = source.components(separatedBy: "\n")

        var i = 0
        var paragraphLines: [String] = []
        var quoteLines: [String] = []
        var listItems: [String] = []
        var listOrdered = false

        func flushParagraph() {
            if !paragraphLines.isEmpty {
                blocks.append(.paragraph(paragraphLines.joined(separator: "\n")))
                paragraphLines.removeAll()
            }
        }
        func flushQuote() {
            if !quoteLines.isEmpty {
                blocks.append(.blockquote(quoteLines.joined(separator: "\n")))
                quoteLines.removeAll()
            }
        }
        func flushList() {
            if !listItems.isEmpty {
                blocks.append(.list(items: listItems, ordered: listOrdered))
                listItems.removeAll()
            }
        }
        func flushAll() {
            flushParagraph()
            flushQuote()
            flushList()
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Fenced code block
            if trimmed.hasPrefix("```") {
                flushAll()
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count {
                    let next = lines[i]
                    if next.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        i += 1
                        break
                    }
                    codeLines.append(next)
                    i += 1
                }
                blocks.append(.codeBlock(language: lang.isEmpty ? nil : lang, code: codeLines.joined(separator: "\n")))
                continue
            }

            // Headings
            if let match = headingMatch(trimmed) {
                flushAll()
                blocks.append(.heading(level: match.level, text: match.text))
                i += 1
                continue
            }

            // Blockquote
            if trimmed.hasPrefix(">") {
                flushParagraph()
                flushList()
                let content = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                quoteLines.append(content)
                i += 1
                continue
            }

            // Bullet list
            if let bullet = bulletItem(trimmed) {
                flushParagraph()
                flushQuote()
                if !listOrdered && !listItems.isEmpty {
                    // already collecting bullet list — keep going
                } else {
                    flushList()
                    listOrdered = false
                }
                listItems.append(bullet)
                i += 1
                continue
            }

            // Numbered list
            if let numbered = numberedItem(trimmed) {
                flushParagraph()
                flushQuote()
                if listOrdered && !listItems.isEmpty {
                    // continue collecting
                } else {
                    flushList()
                    listOrdered = true
                }
                listItems.append(numbered)
                i += 1
                continue
            }

            // Blank line — paragraph/list/quote separator
            if trimmed.isEmpty {
                flushAll()
                i += 1
                continue
            }

            // Default: paragraph line
            flushQuote()
            flushList()
            paragraphLines.append(line)
            i += 1
        }

        flushAll()
        return blocks
    }

    private static func headingMatch(_ line: String) -> (level: Int, text: String)? {
        var level = 0
        for c in line {
            if c == "#" { level += 1 } else { break }
            if level > 6 { return nil }
        }
        guard level >= 1, level <= 6 else { return nil }
        let rest = line.dropFirst(level)
        guard rest.first == " " else { return nil }
        let text = rest.trimmingCharacters(in: .whitespaces)
        return (level, text)
    }

    private static func bulletItem(_ line: String) -> String? {
        if line.hasPrefix("- ") { return String(line.dropFirst(2)) }
        if line.hasPrefix("* ") { return String(line.dropFirst(2)) }
        if line.hasPrefix("+ ") { return String(line.dropFirst(2)) }
        return nil
    }

    private static func numberedItem(_ line: String) -> String? {
        // match "1. ", "12. " etc.
        var idx = line.startIndex
        var sawDigit = false
        while idx < line.endIndex, line[idx].isNumber {
            sawDigit = true
            idx = line.index(after: idx)
        }
        guard sawDigit, idx < line.endIndex, line[idx] == "." else { return nil }
        idx = line.index(after: idx)
        guard idx < line.endIndex, line[idx] == " " else { return nil }
        return String(line[line.index(after: idx)...])
    }
}
