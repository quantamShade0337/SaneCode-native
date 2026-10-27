import SwiftUI

struct ChangedFilesListView: View {
    var files: [FileChange]
    var title: String = "Current Task"
    @Binding var selectedFile: FileChange?
    var openFile: (FileChange) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            if files.isEmpty {
                Text("No changes can be attributed to this room yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(grouped.keys.sorted(), id: \.self) { group in
                    Text(group)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(grouped[group] ?? []) { file in
                        Button {
                            selectedFile = file
                        } label: {
                            HStack {
                                StatusBadge(label: file.status.label, systemImage: "doc", tint: tint(for: file.status))
                                    .frame(width: 86, alignment: .leading)
                                Text(file.path).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 6)
                        .background(selectedFile?.id == file.id ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                        .contextMenu {
                            Button("Open file in Code view") { openFile(file) }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .onChange(of: files) { _, newFiles in
            if let selectedFile, !newFiles.contains(where: { $0.id == selectedFile.id }) {
                self.selectedFile = newFiles.first
            } else if selectedFile == nil {
                selectedFile = newFiles.first
            }
        }
        .onAppear {
            if selectedFile == nil {
                selectedFile = files.first
            }
        }
    }

    private var grouped: [String: [FileChange]] {
        Dictionary(grouping: files, by: { $0.status.label })
    }

    private func tint(for status: FileChangeStatus) -> Color {
        switch status {
        case .modified: .orange
        case .added: .green
        case .deleted: .red
        case .renamed: .blue
        case .untracked: .purple
        }
    }
}
