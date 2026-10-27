import SwiftUI

struct BackendHealthView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Backend Health")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("Run Check") {
                    app.runBackendHealthCheck()
                }
                .buttonStyle(.borderedProminent)
            }

            if let report = app.backendHealthReport {
                Text("Generated \(report.generatedAt, style: .time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(report.items) { item in
                    CardView {
                        HStack(alignment: .top) {
                            Image(systemName: item.isHealthy ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                .foregroundStyle(item.isHealthy ? .green : .red)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.status)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(item.detail)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                            Spacer()
                        }
                    }
                }
            } else {
                EmptyStateView(title: "No health check yet", message: "Run a local backend check to verify storage, Codex CLI, repository access, and room worktrees.")
            }
            Spacer()
        }
        .padding()
        .onAppear {
            if app.backendHealthReport == nil {
                app.runBackendHealthCheck()
            }
        }
    }
}
