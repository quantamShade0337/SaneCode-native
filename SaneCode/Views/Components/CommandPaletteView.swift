import SwiftUI

struct CommandPaletteView: View {
    @EnvironmentObject private var app: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var searchFocused: Bool

    private let commands: [(label: String, systemImage: String)] = [
        ("Open Repository", "folder"),
        ("New Room", "plus.square"),
        ("Run Current Task", "play.fill"),
        ("Cancel Task", "stop.fill"),
        ("Run Checks", "checkmark.seal"),
        ("Show Changes", "arrow.left.arrow.right"),
        ("Open Preview", "eye"),
        ("Start Preview", "play.circle"),
        ("Stop Preview", "stop.circle"),
        ("Open Terminal", "terminal"),
        ("Search Files", "magnifyingglass"),
        ("Open Settings", "gearshape"),
        ("Toggle Sidebar", "sidebar.left"),
        ("Toggle Right Panel", "sidebar.right"),
        ("Toggle Terminal Drawer", "terminal.fill")
    ]

    private var filtered: [(label: String, systemImage: String)] {
        query.isEmpty ? commands : commands.filter { $0.label.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 16))
                TextField("Search commands...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($searchFocused)
                    .onKeyPress(.upArrow) {
                        selectedIndex = max(0, selectedIndex - 1)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        selectedIndex = min(filtered.count - 1, selectedIndex + 1)
                        return .handled
                    }
                    .onKeyPress(.return) {
                        execute(at: selectedIndex)
                        return .handled
                    }
                    .onKeyPress(.escape) {
                        dismiss()
                        return .handled
                    }
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            if filtered.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("No commands match \"\(query)\"")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(filtered.enumerated()), id: \.element.label) { index, command in
                            Button {
                                execute(at: index)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: command.systemImage)
                                        .font(.system(size: 13))
                                        .foregroundStyle(selectedIndex == index ? .primary : .secondary)
                                        .frame(width: 18)
                                    Text(command.label)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selectedIndex == index ? Color.accentColor.opacity(0.12) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 7)
                                )
                            }
                            .buttonStyle(.plain)
                            .onHover { hovered in
                                if hovered { selectedIndex = index }
                            }
                        }
                    }
                    .padding(8)
                }
            }
        }
        .frame(width: 560, height: 400)
        .onAppear {
            searchFocused = true
            selectedIndex = 0
        }
        .onChange(of: query) {
            selectedIndex = 0
        }
    }

    private func execute(at index: Int) {
        guard index < filtered.count else { return }
        app.executeCommandPaletteAction(filtered[index].label)
        dismiss()
    }
}
