import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        Group {
            if app.isScanning {
                RepoLoadingView()
            } else if app.selectedRepository == nil {
                WelcomeView()
            } else {
                MainWorkspaceView()
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = app.toastMessage {
                ToastView(text: toast)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: app.toastMessage)
        .sheet(isPresented: $app.showNewRoom) {
            NewRoomModal()
                .environmentObject(app)
        }
        .sheet(isPresented: $app.showCommandPalette) {
            CommandPaletteView()
                .environmentObject(app)
        }
        .alert("Repository access needed", isPresented: Binding(
            get: { app.repositoryAccessMessage != nil },
            set: { if !$0 { app.repositoryAccessMessage = nil } }
        )) {
            Button("Reselect Folder") {
                app.repositoryAccessMessage = nil
                app.reselectRepositoryForAccess()
            }
            Button("Cancel", role: .cancel) {
                app.repositoryAccessMessage = nil
            }
        } message: {
            Text(app.repositoryAccessMessage ?? "Sanecode needs you to reselect this folder before it can access it.")
        }
    }
}
