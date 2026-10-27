import AppKit
import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var app: AppViewModel
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Hero
            VStack(spacing: 14) {
                Image(systemName: "command.square.fill")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(.tint)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: appeared)

                VStack(spacing: 6) {
                    Text("Sanecode")
                        .font(.system(size: 36, weight: .semibold))
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.12), value: appeared)

                    Text("Local-first coding agents for your repo.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.18), value: appeared)
                }
            }

            // CTA
            Button {
                app.openRepository()
            } label: {
                Label("Open Repository", systemImage: "folder")
                    .padding(.horizontal, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.24), value: appeared)

            // Recent repos
            if !app.repositories.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)

                    VStack(spacing: 4) {
                        ForEach(Array(app.repositories.prefix(6).enumerated()), id: \.element.id) { index, repo in
                            repoRow(repo, delay: 0.28 + Double(index) * 0.05)
                        }
                    }
                }
                .frame(width: 560)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.28), value: appeared)
            }

            Spacer()
        }
        .padding(40)
        .onAppear {
            appeared = true
        }
    }

    private func repoRow(_ repo: Repository, delay: Double) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(repo.name)
                    .font(.callout.weight(.medium))
                Text(PathFormatting.shortened(repo.path))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let branch = repo.branch {
                Text(branch)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())
            }

            HStack(spacing: 4) {
                Button("Open") {
                    app.openRecentRepository(repo)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: repo.path)])
                } label: {
                    Image(systemName: "arrow.up.forward.square")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)

                Button {
                    app.repositories.removeAll { $0.id == repo.id }
                    app.saveState()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
    }
}
