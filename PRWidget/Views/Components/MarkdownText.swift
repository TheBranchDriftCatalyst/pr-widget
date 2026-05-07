import SwiftUI
import CatalystSwift

/// Renders GitHub-flavored markdown to SwiftUI views. Supports paragraphs,
/// fenced code blocks, headings, bullet/numbered lists, blockquotes, and
/// pipe tables. Strips HTML comments and common inline HTML tags
/// (`<sup>`, `<sub>`, `<kbd>`, `<br>`, `<details>`, `<summary>`) before parsing.
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

        case .table(let header, let rows):
            tableView(header: header, rows: rows)

        case .rule:
            Rectangle()
                .fill(Catalyst.subtle.opacity(0.3))
                .frame(height: 1)
                .padding(.vertical, 2)
        }
    }

    private func tableView(header: [String], rows: [[String]]) -> some View {
        let columnCount = max(header.count, rows.map(\.count).max() ?? 0)
        return VStack(alignment: .leading, spacing: 0) {
            tableRow(header, columnCount: columnCount, isHeader: true)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                Divider().opacity(0.3)
                tableRow(row, columnCount: columnCount, isHeader: false)
            }
        }
        .background(Catalyst.background.opacity(0.4), in: .rect(cornerRadius: Catalyst.radiusSM))
        .overlay(
            RoundedRectangle(cornerRadius: Catalyst.radiusSM)
                .strokeBorder(Catalyst.subtle.opacity(0.3), lineWidth: 0.5)
        )
    }

    private func tableRow(_ cells: [String], columnCount: Int, isHeader: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<columnCount, id: \.self) { idx in
                let cell = idx < cells.count ? cells[idx] : ""
                inlineText(cell)
                    .scaledFont(size: fontSize - 1, weight: isHeader ? .semibold : .regular)
                    .foregroundStyle(isHeader ? Catalyst.foreground : foregroundColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                if idx < columnCount - 1 {
                    Rectangle()
                        .fill(Catalyst.subtle.opacity(0.3))
                        .frame(width: 0.5)
                }
            }
        }
        .background(isHeader ? Catalyst.subtle.opacity(0.1) : Color.clear)
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
    case table(header: [String], rows: [[String]])
    case rule
}

enum MarkdownParser {
    static func parse(_ source: String) -> [MarkdownBlock] {
        let cleaned = preprocess(source)
        var blocks: [MarkdownBlock] = []
        let lines = cleaned.components(separatedBy: "\n")

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

            // Horizontal rule (---, ***, ___)
            if isHorizontalRule(trimmed) {
                flushAll()
                blocks.append(.rule)
                i += 1
                continue
            }

            // Pipe table: header row followed by separator row of dashes
            if isTableRow(trimmed),
               i + 1 < lines.count,
               isTableSeparator(lines[i + 1].trimmingCharacters(in: .whitespaces)) {
                flushAll()
                let header = splitTableRow(trimmed)
                var rows: [[String]] = []
                i += 2
                while i < lines.count {
                    let next = lines[i].trimmingCharacters(in: .whitespaces)
                    guard isTableRow(next) else { break }
                    rows.append(splitTableRow(next))
                    i += 1
                }
                blocks.append(.table(header: header, rows: rows))
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

    /// Strip HTML comments and common inline HTML tags that would otherwise
    /// render as literal text under `AttributedString`'s markdown parser.
    static func preprocess(_ source: String) -> String {
        var s = source

        // HTML comments
        s = s.replacingOccurrences(of: "<!--[\\s\\S]*?-->", with: "", options: .regularExpression)

        // <br>, <br/>, <br /> → newline
        s = s.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])

        // Strip wrapping tags but keep inner content (sup/sub/kbd/details/summary/ins/del)
        let wrapTags = ["sup", "sub", "kbd", "details", "summary", "ins", "del", "u", "small"]
        for tag in wrapTags {
            s = s.replacingOccurrences(of: "<\(tag)[^>]*>", with: "", options: [.regularExpression, .caseInsensitive])
            s = s.replacingOccurrences(of: "</\(tag)>", with: "", options: [.regularExpression, .caseInsensitive])
        }

        // Strip stray self-closing or unmatched tags from the above set
        return s
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        guard line.count >= 3 else { return false }
        let chars = Set(line.replacingOccurrences(of: " ", with: ""))
        return chars == ["-"] || chars == ["*"] || chars == ["_"]
    }

    private static func isTableRow(_ line: String) -> Bool {
        guard line.contains("|") else { return false }
        // Ignore lines that are just code or text incidentally containing a pipe
        let stripped = line.hasPrefix("|") ? String(line.dropFirst()) : line
        return stripped.contains("|")
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        guard line.contains("|") else { return false }
        let cells = splitTableRow(line)
        guard !cells.isEmpty else { return false }
        for cell in cells {
            let trimmed = cell.trimmingCharacters(in: .whitespaces)
            // valid cells look like ---, :---, ---:, :---:
            let core = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
            guard !core.isEmpty, core.allSatisfy({ $0 == "-" }) else { return false }
        }
        return true
    }

    private static func splitTableRow(_ line: String) -> [String] {
        var s = line
        if s.hasPrefix("|") { s = String(s.dropFirst()) }
        if s.hasSuffix("|") { s = String(s.dropLast()) }
        return s.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
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
