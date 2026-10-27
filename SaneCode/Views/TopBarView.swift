import SwiftUI

struct TopBarView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        HStack(spacing: 6) {
            panelToggles

            Divider().frame(height: 16).padding(.horizontal, 2)

            breadcrumb

            Spacer()

            if app.terminalViewModel.isRunning {
                StatusBadge(label: "Running", systemImage: "play.circle.fill", tint: .blue)
            }

            actionButtons
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
    }

    private var panelToggles: some View {
        HStack(spacing: 2) {
            panelToggle("sidebar.left", active: app.isSidebarVisible, help: "Toggle Sidebar (⌘⌥S)") {
                withAnimation(.easeInOut(duration: 0.18)) { app.isSidebarVisible.toggle() }
            }
            panelToggle("sidebar.right", active: app.isRightPanelVisible, help: "Toggle Tasks Panel") {
                withAnimation(.easeInOut(duration: 0.18)) { app.isRightPanelVisible.toggle() }
            }
            panelToggle("terminal", active: app.isTerminalDrawerOpen, help: "Toggle Terminal") {
                withAnimation(.easeInOut(duration: 0.18)) { app.isTerminalDrawerOpen.toggle() }
            }
        }
    }

    private var breadcrumb: some View {
        HStack(spacing: 4) {
            if let repo = app.selectedRepository {
                Text(repo.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                if app.selectedRoom != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.quaternary)
                    Text(app.selectedRoom?.title ?? "")
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }
                if let branch = repo.branch {
                    Text(branch)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.05), in: Capsule())
                }
            } else {
                Text("Sanecode")
                    .font(.system(size: 13, weight: .semibold))
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 4) {
            Button {
                app.showNewRoom = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("New Room")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .help("New Room")
            .disabled(app.selectedRepository == nil)

            Button {
                app.openRepository()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                    Text("Open")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .help("Open Repository (⌘O)")
            .keyboardShortcut("o", modifiers: .command)

            Button {
                runChecks()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 12))
                    Text("Run Checks")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .help("Run verification checks")
            .disabled(app.selectedRoom == nil || app.selectedRepository == nil)

            Divider().frame(height: 16)

            iconButton("command", help: "Command Palette (⌘K)") {
                app.showCommandPalette = true
            }
            .keyboardShortcut("k", modifiers: .command)
        }
    }

    private func panelToggle(_ icon: String, active: Bool, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(active ? Color.primary : Color.secondary.opacity(0.5))
                .frame(width: 26, height: 26)
                .background(
                    active ? Color.primary.opacity(0.06) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5)
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func iconButton(_ icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func runChecks() {
        guard let room = app.selectedRoom, let repo = app.selectedRepository else { return }
        guard app.ensureRepositoryAccess(repo) else { return }
        let vm = AgentRoomViewModel(room: room)
        vm.runChecks(repository: repo, terminal: app.terminalViewModel, onSave: app.updateSelectedRoom)
        app.selectedMainTab = .changes
    }
}
