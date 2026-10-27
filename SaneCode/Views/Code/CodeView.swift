import AppKit
import SwiftUI

struct CodeView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        HStack(spacing: 0) {
            if let repo = app.selectedRepository {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Files").font(.headline).padding(.horizontal, 12).padding(.top, 12)
                    FileExplorerView(rootPath: repo.path)
                }
                .frame(width: 260)
                Divider()
                CodeViewerView(rootPath: repo.path, selectedPath: app.selectedFilePath)
                Divider()
                CodeIntelligenceView(rootPath: repo.path) { path in
                    app.selectedFilePath = path
                }
                .frame(width: 300)
            } else {
                EmptyStateView(title: "No repository", message: "Open a repository to inspect code.")
            }
        }
    }
}
