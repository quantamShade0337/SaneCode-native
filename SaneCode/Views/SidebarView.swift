import AppKit
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var app: AppViewModel
    @State private var searchText = ""
    @State private var expandedRepos: Set<UUID> = []
    @State private var renamingRoom: AgentRoom?
    @State private var renameText = ""

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                    projectsHeader
                    ForEach(app.repositories) { repo in
                        repoSection(repo)
                    }
                }
                .padding(.bottom, 8)
            }
            Divider()
            settingsButton
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            if let id = app.selectedRepository?.id { expandedRepos.insert(id) }
        }
        .onChange(of: app.selectedRepository?.id) { _, newID in
            if let id = newID { expandedRepos.insert(id) }
        }
        .alert("Rename Room", isPresented: Binding(
            get: { renamingRoom != nil },
            set: { if !$0 { renamingRoom = nil } }
        )) {
            TextField("Room name", text: $renameText)
            Button("Rename") {
                guard let room = renamingRoom,
                      let index = app.rooms.firstIndex(where: { $0.id == room.id }) else { return }
                app.rooms[index].title = renameText
                if app.selectedRoom?.id == room.id { app.selectedRoom = app.rooms[index] }
                app.saveState()
                renamingRoom = nil
            }
            .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) { renamingRoom = nil }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            Button {
                app.showCommandPalette = true
            } label: {
                Text("⌘K")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.quaternary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .help("Command Palette (⌘K)")
            .keyboardShortcut("k", modifiers: .command)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
    }

    private var projectsHeader: some View {
        HStack(spacing: 4) {
            Text("PROJECTS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                app.openRepository()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Open Repository")
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func repoSection(_ repo: Repository) -> some View {
        let isExpanded = expandedRepos.contains(repo.id)
        let isSelected = app.selectedRepository?.id == repo.id
        let rooms = filteredRooms(for: repo)

        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if expandedRepos.contains(repo.id) {
                    expandedRepos.remove(repo.id)
                } else {
                    expandedRepos.insert(repo.id)
                }
            }
            if !isSelected { app.openRecentRepository(repo) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 10)
                Image(systemName: "folder.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text(repo.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                Spacer()
                if let branch = repo.branch {
                    Text(branch)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)

        if isExpanded {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(rooms) { room in roomRow(room) }
                newRoomRow(for: repo)
            }
            .padding(.leading, 14)
        }
    }

    @ViewBuilder
    private func roomRow(_ room: AgentRoom) -> some View {
        let isSelected = app.selectedRoom?.id == room.id

        Button {
            app.selectedRoom = room
            app.selectedMainTab = .work
        } label: {
            HStack(spacing: 8) {
                statusDot(room.status)
                Text(room.title)
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? .primary : Color.primary.opacity(0.8))
                    .lineLimit(1)
                Spacer()
                Text(relativeTime(room.updatedAt))
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                isSelected ? Color.accentColor.opacity(0.10) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
        .contextMenu {
            Button("Rename") {
                renamingRoom = room
                renameText = room.title
            }
            Button("Duplicate") {
                var copy = room
                copy.id = UUID()
                copy.title = "\(room.title) (copy)"
                copy.messages = []
                copy.changedFiles = []
                copy.diff = ""
                app.rooms.append(copy)
                app.saveState()
            }
            Divider()
            Button("Delete", role: .destructive) {
                app.rooms.removeAll { $0.id == room.id }
                if app.selectedRoom?.id == room.id { app.selectedRoom = app.rooms.first }
                app.saveState()
            }
            Divider()
            Button("Reveal Session File") {
                NSWorkspace.shared.open(URL(fileURLWithPath: app.sessionStore.storagePath))
            }
        }
    }

    private func newRoomRow(for repo: Repository) -> some View {
        Button {
            if app.selectedRepository?.id != repo.id { app.openRecentRepository(repo) }
            app.showNewRoom = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(width: 8)
                Text("New Room")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }

    private var settingsButton: some View {
        Button {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                Text("Settings")
                    .font(.system(size: 13))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func filteredRooms(for repo: Repository) -> [AgentRoom] {
        let rooms = app.rooms.filter { $0.repositoryPath == repo.path }
        if searchText.isEmpty { return rooms }
        return rooms.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private func statusDot(_ status: RoomStatus) -> some View {
        Circle()
            .fill(statusColor(status))
            .frame(width: 6, height: 6)
    }

    private func statusColor(_ status: RoomStatus) -> Color {
        switch status {
        case .ready, .cancelled, .reverted: return Color.secondary.opacity(0.25)
        case .planning, .running: return .blue
        case .needsReview: return .orange
        case .checksPassed: return .green
        case .checksFailed: return .red
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

