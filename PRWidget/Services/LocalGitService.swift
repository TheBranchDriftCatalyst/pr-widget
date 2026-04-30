import Foundation

actor LocalGitService {

    enum GitError: Error, LocalizedError {
        case commandFailed(String)
        case notARepository(String)

        var errorDescription: String? {
            switch self {
            case .commandFailed(let msg): "Git command failed: \(msg)"
            case .notARepository(let path): "Not a git repository: \(path)"
            }
        }
    }

    // MARK: - Discover Repos

    /// Scans a workspace directory (1–2 levels deep) for git repos and returns their remote origin nameWithOwner.
    func discoverRepos(in workspaceRoot: String) async -> [DiscoveredRepo] {
        let fm = FileManager.default
        var results: [DiscoveredRepo] = []

        guard let entries = try? fm.contentsOfDirectory(atPath: workspaceRoot) else { return [] }

        for entry in entries {
            let entryPath = (workspaceRoot as NSString).appendingPathComponent(entry)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: entryPath, isDirectory: &isDir), isDir.boolValue else { continue }

            // Check if this entry itself is a git repo
            if fm.fileExists(atPath: (entryPath as NSString).appendingPathComponent(".git")) {
                if let nwo = await parseRemoteOrigin(repoPath: entryPath) {
                    results.append(DiscoveredRepo(nameWithOwner: nwo, localPath: entryPath))
                }
                continue
            }

            // Check one level deeper (e.g. workspace/@org/repo)
            guard let subEntries = try? fm.contentsOfDirectory(atPath: entryPath) else { continue }
            for subEntry in subEntries {
                let subPath = (entryPath as NSString).appendingPathComponent(subEntry)
                guard fm.fileExists(atPath: subPath, isDirectory: &isDir), isDir.boolValue else { continue }
                if fm.fileExists(atPath: (subPath as NSString).appendingPathComponent(".git")) {
                    if let nwo = await parseRemoteOrigin(repoPath: subPath) {
                        results.append(DiscoveredRepo(nameWithOwner: nwo, localPath: subPath))
                    }
                }
            }
        }

        return results
    }

    // MARK: - List Branches

    func listBranches(repoPath: String) async throws -> [LocalBranchInfo] {
        let output = try await runGit(
            args: ["for-each-ref", "--format=%(refname:short)|%(authorname)|%(committerdate:iso-strict)|%(HEAD)", "refs/heads/"],
            directory: repoPath
        )

        let decoder = ISO8601DateFormatter()
        decoder.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return output.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "|", maxSplits: 3)
            guard parts.count >= 3 else { return nil }
            let name = String(parts[0])
            let committer = String(parts[1])
            let dateStr = String(parts[2])
            let isCurrent = parts.count > 3 && parts[3] == "*"
            let date = decoder.date(from: dateStr) ?? .distantPast
            return LocalBranchInfo(name: name, lastCommitter: committer, lastCommitDate: date, isCurrent: isCurrent)
        }
    }

    // MARK: - Merge Check

    func isMerged(branch: String, into target: String, repoPath: String) async -> Bool {
        guard let output = try? await runGit(
            args: ["branch", "--merged", target, "--format=%(refname:short)"],
            directory: repoPath
        ) else {
            return false
        }
        return output.split(separator: "\n").contains { $0.trimmingCharacters(in: .whitespaces) == branch }
    }

    // MARK: - Delete Branch

    func deleteBranch(_ name: String, repoPath: String, force: Bool = false) async throws {
        NSLog("[PArr] Deleting branch '%@' in %@%@", name, repoPath, force ? " [force]" : "")
        let flag = force ? "-D" : "-d"
        _ = try await runGit(args: ["branch", flag, name], directory: repoPath)
        NSLog("[PArr] ✓ Deleted branch '%@'", name)
    }

    // MARK: - Private

    private func parseRemoteOrigin(repoPath: String) async -> String? {
        guard let url = try? await runGit(args: ["remote", "get-url", "origin"], directory: repoPath) else {
            return nil
        }
        return extractNameWithOwner(from: url.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Extracts "owner/repo" from various git remote URL formats.
    private func extractNameWithOwner(from remoteURL: String) -> String? {
        let stripped = remoteURL.replacing(".git", with: "")

        // SCP-style SSH: git@github.com:owner/repo.git
        if stripped.contains("git@") && !stripped.hasPrefix("ssh://") {
            if let colonIndex = stripped.lastIndex(of: ":") {
                return String(stripped[stripped.index(after: colonIndex)...])
            }
        }

        // ssh://git@github.com/owner/repo.git  OR  https://github.com/owner/repo.git
        if let url = URL(string: stripped) {
            let components = url.pathComponents.filter { $0 != "/" }
            if components.count >= 2 {
                return "\(components[components.count - 2])/\(components[components.count - 1])"
            }
        }

        return nil
    }

    private func runGit(args: [String], directory: String) async throws -> String {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = URL(filePath: directory)

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            NSLog("[PArr] ❌ git %@ failed (exit %d) in %@: %@", args.joined(separator: " "), process.terminationStatus, directory, errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
            throw GitError.commandFailed(errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return output
    }
}
