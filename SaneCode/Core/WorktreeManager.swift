import Foundation

struct WorktreeManager {
    func prepareWorktree(for room: AgentRoom, repository: Repository) -> RoomWorktree {
        if let existing = room.worktree, existing.status == .ready, FileManager.default.fileExists(atPath: existing.worktreePath) {
            return existing
        }

        let baseDirectory = applicationSupportDirectory().appendingPathComponent("Worktrees", isDirectory: true)
        let worktreeURL = baseDirectory.appendingPathComponent(room.id.uuidString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        } catch {
            return failed(room: room, repository: repository, path: worktreeURL.path, message: error.localizedDescription)
        }

        if FileManager.default.fileExists(atPath: worktreeURL.path) {
            return RoomWorktree(roomID: room.id, originalPath: repository.path, worktreePath: worktreeURL.path, branch: repository.branch, status: .ready)
        }

        let result = shell("git worktree add --detach \(quote(worktreeURL.path)) HEAD", path: repository.path)
        guard result.exitCode == 0 else {
            return failed(room: room, repository: repository, path: worktreeURL.path, message: result.output)
        }

        return RoomWorktree(roomID: room.id, originalPath: repository.path, worktreePath: worktreeURL.path, branch: repository.branch, status: .ready)
    }

    func keepTrackedChanges(from worktree: RoomWorktree) -> (success: Bool, message: String) {
        guard worktree.status == .ready else {
            return (false, "Room worktree is not ready.")
        }
        let diff = shell("git diff --binary --no-ext-diff", path: worktree.worktreePath)
        guard diff.exitCode == 0 else {
            return (false, diff.output)
        }
        guard !diff.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (true, "No tracked changes to keep.")
        }

        let apply = shellWithInput("git apply --whitespace=nowarn -", input: diff.output, path: worktree.originalPath)
        guard apply.exitCode == 0 else {
            return (false, apply.output)
        }
        return (true, "Tracked room changes were applied to the original repository. Untracked files were left in the room worktree.")
    }

    func keepUntrackedFiles(_ files: [FileChange], from worktree: RoomWorktree) -> (success: Bool, message: String) {
        let untracked = files.filter { $0.status == .untracked }
        guard !untracked.isEmpty else { return (true, "No untracked files selected.") }

        for file in untracked {
            let source = URL(fileURLWithPath: worktree.worktreePath).appendingPathComponent(file.path)
            let destination = URL(fileURLWithPath: worktree.originalPath).appendingPathComponent(file.path)
            do {
                try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                if FileManager.default.fileExists(atPath: destination.path) {
                    return (false, "Destination already exists: \(file.path)")
                }
                try FileManager.default.copyItem(at: source, to: destination)
            } catch {
                return (false, "Could not copy \(file.path): \(error.localizedDescription)")
            }
        }

        return (true, "Copied \(untracked.count) untracked files to the original repository.")
    }

    func discardWorktree(_ worktree: RoomWorktree) -> (success: Bool, message: String) {
        guard FileManager.default.fileExists(atPath: worktree.worktreePath) else {
            return (true, "Room worktree was already removed.")
        }
        let result = shell("git worktree remove --force \(quote(worktree.worktreePath))", path: worktree.originalPath)
        guard result.exitCode == 0 else {
            return (false, result.output)
        }
        return (true, "Room worktree discarded.")
    }

    func applyPatchProposal(_ patch: String, to path: String) -> (success: Bool, message: String) {
        let trimmed = extractPatch(from: patch)
        guard !trimmed.isEmpty else {
            return (false, "No diff-style patch was found in the proposal.")
        }

        let check = shellWithInput("git apply --check -", input: trimmed, path: path)
        guard check.exitCode == 0 else {
            return (false, "Patch cannot be applied cleanly. \(check.output)")
        }

        let apply = shellWithInput("git apply --whitespace=nowarn -", input: trimmed, path: path)
        guard apply.exitCode == 0 else {
            return (false, apply.output)
        }

        return (true, "Patch proposal applied to the room.")
    }

    private func failed(room: AgentRoom, repository: Repository, path: String, message: String) -> RoomWorktree {
        RoomWorktree(roomID: room.id, originalPath: repository.path, worktreePath: path, branch: repository.branch, status: .failed, errorMessage: message)
    }

    private func applicationSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return base.appendingPathComponent("Sanecode", isDirectory: true)
    }

    private func quote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func extractPatch(from text: String) -> String {
        if let range = text.range(of: "diff --git") {
            return String(text[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if text.contains("--- ") && text.contains("+++ ") && text.contains("@@") {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    private func shell(_ command: String, path: String) -> (exitCode: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = URL(fileURLWithPath: path)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
        } catch {
            return (1, error.localizedDescription)
        }
    }

    private func shellWithInput(_ command: String, input: String, path: String) -> (exitCode: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = URL(fileURLWithPath: path)
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        do {
            try process.run()
            if let data = input.data(using: .utf8) {
                inputPipe.fileHandleForWriting.write(data)
            }
            try? inputPipe.fileHandleForWriting.close()
            process.waitUntilExit()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
        } catch {
            return (1, error.localizedDescription)
        }
    }
}
