import SwiftUI
import CatalystSwift

struct DiffContentView: View {
    let file: PRFileDiff
    var onReply: (String, String) async -> Void  // (threadId, body)

    private var hunks: [DiffHunk] {
        guard let patch = file.patch else { return [] }
        return DiffParser.parse(patch)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // File header
                fileHeader

                if file.patch == nil {
                    noPatchView
                } else {
                    ForEach(hunks) { hunk in
                        hunkHeader(hunk)
                        ForEach(hunk.lines) { line in
                            diffLineView(line)
                            // Insert inline comment threads at this line
                            ForEach(threadsAtLine(line)) { thread in
                                InlineCommentThread(thread: thread) { body in
                                    await onReply(thread.id, body)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var fileHeader: some View {
        HStack(spacing: 8) {
            Text(file.path)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Catalyst.foreground)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            HStack(spacing: 4) {
                Text("+\(file.additions)")
                    .foregroundStyle(Catalyst.cyan)
                Text("-\(file.deletions)")
                    .foregroundStyle(Catalyst.red)
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard()
    }

    private var noPatchView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 24))
                .foregroundStyle(Catalyst.subtle)
            Text("Binary file or diff too large")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Catalyst.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func hunkHeader(_ hunk: DiffHunk) -> some View {
        Text(hunk.header)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(Catalyst.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Catalyst.blue.opacity(0.08))
    }

    private func diffLineView(_ line: DiffLine) -> some View {
        HStack(spacing: 0) {
            // Old line number
            Text(line.oldLineNumber.map { "\($0)" } ?? "")
                .frame(width: 45, alignment: .trailing)
                .foregroundStyle(Catalyst.subtle)

            // New line number
            Text(line.newLineNumber.map { "\($0)" } ?? "")
                .frame(width: 45, alignment: .trailing)
                .foregroundStyle(Catalyst.subtle)

            // Prefix
            Text(linePrefix(line.type))
                .frame(width: 16, alignment: .center)
                .foregroundStyle(linePrefixColor(line.type))

            // Content
            Text(line.content)
                .foregroundStyle(lineContentColor(line.type))

            Spacer()
        }
        .font(.system(size: 12, design: .monospaced))
        .padding(.vertical, 0.5)
        .background(lineBackground(line.type))
        .textSelection(.enabled)
    }

    private func linePrefix(_ type: DiffLine.LineType) -> String {
        switch type {
        case .addition: "+"
        case .deletion: "-"
        case .context: " "
        }
    }

    private func linePrefixColor(_ type: DiffLine.LineType) -> Color {
        switch type {
        case .addition: Catalyst.cyan
        case .deletion: Catalyst.red
        case .context: Catalyst.subtle
        }
    }

    private func lineContentColor(_ type: DiffLine.LineType) -> Color {
        switch type {
        case .addition: Catalyst.foreground
        case .deletion: Catalyst.foreground.opacity(0.7)
        case .context: Catalyst.muted
        }
    }

    private func lineBackground(_ type: DiffLine.LineType) -> Color {
        switch type {
        case .addition: Catalyst.cyan.opacity(0.08)
        case .deletion: Catalyst.red.opacity(0.08)
        case .context: .clear
        }
    }

    private func threadsAtLine(_ line: DiffLine) -> [PRReviewThread] {
        file.reviewThreads.filter { thread in
            guard let threadLine = thread.line else { return false }
            switch thread.diffSide {
            case .LEFT:
                return line.oldLineNumber == threadLine
            case .RIGHT:
                return line.newLineNumber == threadLine
            }
        }
    }
}
