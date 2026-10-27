import SwiftUI

struct PreviewView: View {
    @EnvironmentObject private var app: AppViewModel
    @StateObject private var viewModel = PreviewViewModel()

    var body: some View {
        if let repo = app.selectedRepository {
            VStack(spacing: 0) {
                PreviewToolbarView(viewModel: viewModel, repository: repo)
                Divider()
                if viewModel.url.isEmpty {
                    DevServerView(viewModel: viewModel, repository: repo)
                } else {
                    BrowserPreviewView(bridge: viewModel.bridge)
                }
                ScreenshotCaptureView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadScreenshots(from: app.selectedRoom)
            }
            .onChange(of: app.selectedRoom?.id) { _, _ in
                viewModel.loadScreenshots(from: app.selectedRoom)
            }
        } else {
            EmptyStateView(title: "Preview your app", message: "Open a repository to start a local dev server.", systemImage: "safari")
        }
    }
}
