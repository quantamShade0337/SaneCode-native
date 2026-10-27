import SwiftUI

struct ChangesView: View {
    @EnvironmentObject private var app: AppViewModel
    @State private var showUndo = false
    @State private var selectedFile: FileChange?

    var body: some View {
        if let repo = app.selectedRepository, let room = app.selectedRoom {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                    Text("\(room.changeSets.last?.roomChangedFiles.count ?? room.changedFiles.count) changes from this room")
                            .font(.title2.weight(.semibold))
                        Spacer()
                        Button("Refresh Diff") { refresh(repo: repo, room: room) }
                        Button("Run Checks") { runChecks(repo: repo, room: room) }
                        Button("Keep Changes") {
                            keepChanges(room)
                        }
                        if room.worktree?.status == .ready {
                            Button("Discard Room", role: .destructive) { discardRoom(room) }
                        }
                        Button("Undo Room Changes", role: .destructive) { showUndo = true }
                    }
                    if let worktree = room.worktree, worktree.status == .ready {
                        Label("Reviewing isolated room worktree. Keep Changes applies tracked changes back to the original repo.", systemImage: "square.split.2x1")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if room.hadPreExistingChanges {
                        Label("This repo already had changes before this room started. Some changes may not belong to this room.", systemImage: "exclamationmark.triangle")
                            .font(.callout)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(12)
                Divider()
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        changeSections(room: room)
                    }
                        .frame(width: 260)
                    Divider()
                    VStack(spacing: 0) {
                        selectedFileActions(repo: repo, room: room)
                        Divider()
                        DiffViewerView(
                            diff: selectedDiff(repo: repo, room: room).text,
                            title: selectedDiff(repo: repo, room: room).title,
                            isFallback: selectedDiff(repo: repo, room: room).isFallback
                        )
                    }
                }
            }
            .sheet(isPresented: $showUndo) {
                UndoChangesModal(repository: repo, room: room)
                    .environmentObject(app)
            }
            .onAppear {
                if room.diff.isEmpty { refresh(repo: repo, room: room) }
                if selectedFile == nil {
                    selectedFile = room.changedFiles.first
                }
            }
        } else {
            EmptyStateView(title: "No changes", message: "Open a repository and run a task to review changes.")
        }
    }

    private func changeSections(room: AgentRoom) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ChangedFilesListView(files: room.changeSets.last?.roomChangedFiles ?? room.changedFiles, title: "Changes from this room", selectedFile: $selectedFile, openFile: openInCode)
                if let changeSet = room.changeSets.last {
                    ChangedFilesListView(files: changeSet.existingChangedFiles, title: "Existing repo changes", selectedFile: $selectedFile, openFile: openInCode)
                    ChangedFilesListView(files: changeSet.untrackedFiles, title: "Untracked files", selectedFile: $selectedFile, openFile: openInCode)
                    Text("Attribution confidence: \(changeSet.attributionConfidence.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                }
            }
        }
    }

    @ViewBuilder
    private func selectedFileActions(repo: Repository, room: AgentRoom) -> some View {
        HStack {
            if let selectedFile {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedFile.path)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(selectedFile.status.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Copy file path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(selectedFile.path, forType: .string)
                }
                Button("Open file in Code view") {
                    openInCode(selectedFile)
                }
                Button("Undo tracked changes", role: .destructive) {
                    undoSelectedFile(selectedFile, repo: repo, room: room)
                }
                .disabled(selectedFile.status == .untracked)
            } else {
                Text("Select a file to review.")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(10)
    }

    private func selectedDiff(repo: Repository, room: AgentRoom) -> (text: String, title: String, isFallback: Bool) {
        let path = reviewPath(repo: repo, room: room)
        let rawDiff = room.diff.isEmpty ? GitManager().diff(path: path) : room.diff
        guard let selectedFile else {
            return (rawDiff, "Raw Diff", true)
        }

        let fileDiff = GitManager().diff(path: path, file: selectedFile)
        if fileDiff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (rawDiff, selectedFile.path, true)
        }
        return (fileDiff, selectedFile.path, false)
    }

    private func refresh(repo: Repository, room: AgentRoom) {
        guard app.ensureRepositoryAccess(repo) else { return }
        var updated = room
        let path = reviewPath(repo: repo, room: room)
        updated.diff = GitManager().diff(path: path)
        updated.changedFiles = GitManager().changesSinceSnapshot(path: path, snapshot: room.safetySnapshot)
        if let selectedFile, !updated.changedFiles.contains(where: { $0.id == selectedFile.id }) {
            self.selectedFile = updated.changedFiles.first
        } else if selectedFile == nil {
            selectedFile = updated.changedFiles.first
        }
        app.updateSelectedRoom(updated)
    }

    private func runChecks(repo: Repository, room: AgentRoom) {
        guard app.ensureRepositoryAccess(repo) else { return }
        let viewModel = AgentRoomViewModel(room: room)
        viewModel.runChecks(repository: repo, terminal: app.terminalViewModel, onSave: app.updateSelectedRoom)
    }

    private func openInCode(_ file: FileChange) {
        app.selectedFilePath = file.path
        app.selectedMainTab = .code
    }

    private func undoSelectedFile(_ file: FileChange, repo: Repository, room: AgentRoom) {
        guard app.ensureRepositoryAccess(repo) else { return }
        do {
            try GitManager().revertTrackedChange(path: reviewPath(repo: repo, room: room), file: file)
            refresh(repo: repo, room: room)
        } catch {
            var updated = room
            updated.messages.append(AgentMessage(roomID: room.id, kind: .error, text: "Could not undo \(file.path): \(error.localizedDescription)"))
            app.updateSelectedRoom(updated)
        }
    }

    private func reviewPath(repo: Repository, room: AgentRoom) -> String {
        if let worktree = room.worktree, worktree.status == .ready {
            return worktree.worktreePath
        }
        return repo.path
    }

    private func keepChanges(_ room: AgentRoom) {
        let viewModel = AgentRoomViewModel(room: room)
        viewModel.keepRoomChanges(onSave: app.updateSelectedRoom)
    }

    private func discardRoom(_ room: AgentRoom) {
        let viewModel = AgentRoomViewModel(room: room)
        viewModel.discardRoomWorktree(onSave: app.updateSelectedRoom)
    }
}
