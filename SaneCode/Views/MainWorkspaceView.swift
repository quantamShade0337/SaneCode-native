import SwiftUI

struct MainWorkspaceView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            TopBarView()
            Divider()
            HStack(spacing: 0) {
                if app.isSidebarVisible {
                    SidebarView()
                        .frame(width: 250)
                        .transition(.move(edge: .leading))
                    Divider()
                }

                VStack(spacing: 0) {
                    tabBar
                    Divider()
                    ZStack {
                        switch app.selectedMainTab {
                        case .work: WorkView()
                        case .code: CodeView()
                        case .changes: ChangesView()
                        case .preview: PreviewView()
                        case .terminal: TerminalView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.easeInOut(duration: 0.12), value: app.selectedMainTab)
                }

                if app.isRightPanelVisible {
                    Divider()
                    NextActionsView()
                        .frame(width: 260)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.easeInOut(duration: 0.18), value: app.isSidebarVisible)
            .animation(.easeInOut(duration: 0.18), value: app.isRightPanelVisible)

            if app.isTerminalDrawerOpen {
                Divider()
                TerminalDrawerView()
                    .frame(height: 180)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: app.isTerminalDrawerOpen)
    }

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(MainTab.allCases) { tab in
                tabButton(tab)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func tabButton(_ tab: MainTab) -> some View {
        let isSelected = app.selectedMainTab == tab

        return Button {
            app.selectedMainTab = tab
        } label: {
            HStack(spacing: 5) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 11, weight: .medium))
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: .medium))
                badge(for: tab)
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                isSelected ? Color.primary.opacity(0.07) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func badge(for tab: MainTab) -> some View {
        switch tab {
        case .work:
            let isRunning = app.selectedRoom?.status == .running || app.selectedRoom?.status == .planning
            if isRunning {
                Circle().fill(Color.blue).frame(width: 6, height: 6)
            }
        case .changes:
            let count = app.selectedRoom?.changedFiles.count ?? 0
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.orange, in: Capsule())
            }
        case .terminal:
            if app.terminalViewModel.isRunning {
                Circle().fill(Color.green).frame(width: 6, height: 6)
            }
        default:
            EmptyView()
        }
    }
}
