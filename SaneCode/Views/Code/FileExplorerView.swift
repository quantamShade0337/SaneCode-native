import SwiftUI

struct FileExplorerView: View {
    @EnvironmentObject private var app: AppViewModel
    var rootPath: String
    @State private var search = ""

    private var files: [String] {
        guard let enumerator = FileManager.default.enumerator(atPath: rootPath) else { return [] }
        var results: [String] = []
        for case let file as String in enumerator {
            if file.contains("/.git/") || file.hasPrefix(".git/") || file.contains("/node_modules/") { continue }
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: "\(rootPath)/\(file)", isDirectory: &isDirectory)
            if !isDirectory.boolValue {
                if search.isEmpty || file.localizedCaseInsensitiveContains(search) {
                    results.append(file)
                }
            }
            if results.count >= 160 { break }
        }
        return results.sorted()
    }

    var body: some View {
        VStack(spacing: 8) {
            TextField("Search files...", text: $search)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 8)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(files, id: \.self) { file in
                        Button {
                            app.selectedFilePath = file
                            app.selectedMainTab = .code
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.secondary)
                                Text(file)
                                    .lineLimit(1)
                                Spacer()
                                if let marker = marker(for: file) {
                                    Text(marker)
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.orange)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(app.selectedFilePath == file ? Color.accentColor.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func marker(for file: String) -> String? {
        app.selectedRepository?.statusSummary.first(where: { $0.path == file })?.status.rawValue
    }
}
