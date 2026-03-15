import Foundation

struct DiffHunk: Identifiable, Sendable {
    let id: Int
    let header: String
    let oldStart: Int
    let newStart: Int
    let lines: [DiffLine]
}

struct DiffLine: Identifiable, Sendable {
    let id: Int
    let type: LineType
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?

    enum LineType: Sendable {
        case context, addition, deletion
    }
}

enum DiffParser {
    private static let hunkHeaderPattern = try! NSRegularExpression(
        pattern: #"^@@\s+-(\d+)(?:,\d+)?\s+\+(\d+)(?:,\d+)?\s+@@(.*)$"#
    )

    static func parse(_ patch: String) -> [DiffHunk] {
        let lines = patch.components(separatedBy: "\n")
        var hunks: [DiffHunk] = []
        var currentLines: [DiffLine] = []
        var currentHeader = ""
        var oldStart = 0
        var newStart = 0
        var oldLine = 0
        var newLine = 0
        var lineId = 0
        var hunkId = 0
        var inHunk = false

        for line in lines {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)

            if let match = hunkHeaderPattern.firstMatch(in: line, range: range) {
                // Save previous hunk
                if inHunk && !currentLines.isEmpty {
                    hunks.append(DiffHunk(
                        id: hunkId,
                        header: currentHeader,
                        oldStart: oldStart,
                        newStart: newStart,
                        lines: currentLines
                    ))
                    hunkId += 1
                }

                oldStart = Int(nsLine.substring(with: match.range(at: 1))) ?? 0
                newStart = Int(nsLine.substring(with: match.range(at: 2))) ?? 0
                let context = match.range(at: 3).location != NSNotFound
                    ? nsLine.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespaces)
                    : ""
                currentHeader = context.isEmpty ? line : line
                oldLine = oldStart
                newLine = newStart
                currentLines = []
                inHunk = true
                continue
            }

            guard inHunk else { continue }

            if line.hasPrefix("+") {
                currentLines.append(DiffLine(
                    id: lineId,
                    type: .addition,
                    content: String(line.dropFirst()),
                    oldLineNumber: nil,
                    newLineNumber: newLine
                ))
                newLine += 1
            } else if line.hasPrefix("-") {
                currentLines.append(DiffLine(
                    id: lineId,
                    type: .deletion,
                    content: String(line.dropFirst()),
                    oldLineNumber: oldLine,
                    newLineNumber: nil
                ))
                oldLine += 1
            } else if line.hasPrefix(" ") || line.isEmpty {
                let content = line.isEmpty ? "" : String(line.dropFirst())
                currentLines.append(DiffLine(
                    id: lineId,
                    type: .context,
                    content: content,
                    oldLineNumber: oldLine,
                    newLineNumber: newLine
                ))
                oldLine += 1
                newLine += 1
            } else if line.hasPrefix("\\") {
                // "\ No newline at end of file" — skip
                continue
            }
            lineId += 1
        }

        // Save last hunk
        if inHunk && !currentLines.isEmpty {
            hunks.append(DiffHunk(
                id: hunkId,
                header: currentHeader,
                oldStart: oldStart,
                newStart: newStart,
                lines: currentLines
            ))
        }

        return hunks
    }
}
