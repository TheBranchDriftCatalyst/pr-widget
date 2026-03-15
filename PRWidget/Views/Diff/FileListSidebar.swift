import SwiftUI
import CatalystSwift

struct FileListSidebar: View {
    let files: [PRFileDiff]
    @Binding var selectedPath: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(files) { file in
                    fileRow(file)
                    if file.id != files.last?.id {
                        GlowDivider()
                    }
                }
            }
        }
        .frame(minWidth: 180, idealWidth: 220, maxWidth: 280)
    }

    private func fileRow(_ file: PRFileDiff) -> some View {
        Button {
            selectedPath = file.path
        } label: {
            HStack(spacing: 6) {
                changeTypeIcon(file.status)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.path.components(separatedBy: "/").last ?? file.path)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Catalyst.foreground)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(file.path)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Catalyst.subtle)
                        .lineLimit(1)
                        .truncationMode(.head)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    HStack(spacing: 2) {
                        Text("+\(file.additions)")
                            .foregroundStyle(Catalyst.cyan)
                        Text("-\(file.deletions)")
                            .foregroundStyle(Catalyst.red)
                    }
                    .font(.system(size: 10, design: .monospaced))

                    let threadCount = file.reviewThreads.count
                    let unresolvedCount = file.reviewThreads.filter { !$0.isResolved }.count
                    if threadCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "text.bubble.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Catalyst.blue)

                            if unresolvedCount == threadCount {
                                Text("\(threadCount)")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Catalyst.blue)
                            } else {
                                Text("\(unresolvedCount)")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Catalyst.blue)
                                Text("/")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Catalyst.subtle)
                                Text("\(threadCount)")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Catalyst.subtle)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selectedPath == file.path ? Catalyst.cyan.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private func changeTypeIcon(_ status: FileChangeType) -> some View {
        let (icon, color): (String, Color) = switch status {
        case .added: ("plus.circle.fill", Catalyst.cyan)
        case .removed: ("minus.circle.fill", Catalyst.red)
        case .modified: ("pencil.circle.fill", Catalyst.yellow)
        case .renamed: ("arrow.right.circle.fill", Catalyst.blue)
        case .copied: ("doc.on.doc.fill", Catalyst.muted)
        case .changed, .unchanged: ("circle.fill", Catalyst.subtle)
        }

        return Image(systemName: icon)
            .font(.system(size: 12))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.4), radius: 2)
    }
}
