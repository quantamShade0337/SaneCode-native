import Foundation

struct GitManager {
    func isGitRepo(path: String) -> Bool {
        shell("git rev-parse --is-inside-work-tree", path: path).trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }

    func currentBranch(path: String) -> String? {
        let branch = shell("git branch --show-current", path: path).trimmingCharacters(in: .whitespacesAndNewlines)
        return branch.isEmpty ? nil : branch
    }

    func remoteURL(path: String) -> String? {
        let remote = shell("git config --get remote.origin.url", path: path).trimmingCharacters(in: .whitespacesAndNewlines)
        return remote.isEmpty ? nil : remote
    }

    func dirtyFiles(path: String) -> [FileChange] {
        statusPorcelain(path: path)
            .split(separator: "\n")
            .compactMap { line in
                let text = String(line)
                guard text.count >= 4 else { return nil }
                let statusText = String(text.prefix(2)).trimmingCharacters(in: .whitespaces)
                let filePath = String(text.dropFirst(3))
                let status: FileChangeStatus
                if statusText.contains("A") {
                    status = .added
                } else if statusText.contains("D") {
                    status = .deleted
                } else if statusText.contains("?") {
                    status = .untracked
                } else if statusText.contains("R") {
                    status = .renamed
                } else {
                    status = .modified
                }
                return FileChange(path: filePath, status: status)
            }
    }

    func statusPorcelain(path: String) -> String {
        shell("git status --porcelain", path: path)
    }

    func diff(path: String) -> String {
        shell("git diff --no-ext-diff", path: path)
    }

    func diff(path: String, file: FileChange) -> String {
        guard file.status != .untracked else { return "" }
        let quoted = quote(file.path)
        return shell("git diff --no-ext-diff -- \(quoted)", path: path)
    }

    func safetySnapshot(path: String, roomID: UUID) -> GitSafetySnapshot {
        GitSafetySnapshot(
            roomID: roomID,
            status: dirtyFiles(path: path),
            diff: diff(path: path)
        )
    }

    func baseline(path: String, roomID: UUID, queuedPromptID: UUID? = nil, branch: String?) -> GitBaseline {
        let status = dirtyFiles(path: path)
        let tracked = status.filter { $0.status != .untracked }
        let untracked = status.filter { $0.status == .untracked }
        let diff = diff(path: path)
        return GitBaseline(
            roomID: roomID,
            queuedPromptID: queuedPromptID,
            branch: branch,
            statusPorcelain: statusPorcelain(path: path),
            diff: diff,
            trackedChangedFiles: tracked,
            untrackedFiles: untracked,
            wasDirty: !status.isEmpty || !diff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
    }

    func changeSet(path: String, roomID: UUID, queuedPromptID: UUID? = nil, baseline: GitBaseline) -> RoomChangeSet {
        let current = dirtyFiles(path: path)
        let baselineIDs = Set((baseline.trackedChangedFiles + baseline.untrackedFiles).map(\.id))
        let roomFiles = current.filter { !baselineIDs.contains($0.id) && $0.status != .untracked }
        let existing = current.filter { baselineIDs.contains($0.id) && $0.status != .untracked }
        let untracked = current.filter { $0.status == .untracked }
        let confidence: ChangeAttributionConfidence = baseline.wasDirty ? (roomFiles.isEmpty ? .low : .medium) : .high
        return RoomChangeSet(
            roomID: roomID,
            queuedPromptID: queuedPromptID,
            baselineID: baseline.id,
            roomChangedFiles: roomFiles,
            existingChangedFiles: existing,
            untrackedFiles: untracked,
            attributionConfidence: confidence,
            warningMessage: baseline.wasDirty ? "This repo already had changes before this room started. Sanecode separated them where possible, but review carefully." : nil
        )
    }

    func changesSinceSnapshot(path: String, snapshot: GitSafetySnapshot?) -> [FileChange] {
        let current = dirtyFiles(path: path)
        guard let snapshot else { return current }
        let before = Set(snapshot.status.map { "\($0.path)|\($0.status.rawValue)" })
        return current.filter { !before.contains("\($0.path)|\($0.status.rawValue)") }
    }

    func revertTrackedChanges(path: String, files: [FileChange]) throws {
        let tracked = files.filter { $0.status != .untracked }.map(\.path)
        guard !tracked.isEmpty else { return }
        let quoted = tracked.map(quote).joined(separator: " ")
        _ = shell("git restore -- \(quoted)", path: path)
    }

    func revertTrackedChange(path: String, file: FileChange) throws {
        guard file.status != .untracked else { return }
        _ = shell("git restore -- \(quote(file.path))", path: path)
    }

    private func quote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func shell(_ command: String, path: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = URL(fileURLWithPath: path)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
