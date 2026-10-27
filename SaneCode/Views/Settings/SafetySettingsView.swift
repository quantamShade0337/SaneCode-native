import SwiftUI

struct SafetySettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    private let alwaysRequireApproval = [
        "Package installs (npm, pnpm, yarn, bun add)",
        "File deletion (rm)",
        "Git push to remote",
        "Database migrations",
        "Secret file access (.env, credentials)",
        "Lockfile changes"
    ]

    private let alwaysBlocked = [
        "rm -rf (recursive delete)",
        "sudo (privilege escalation)",
        "curl | bash / wget | bash (pipe to shell)",
        "git push --force",
        "git reset --hard",
        "git clean -fd",
        "Production deploy commands"
    ]

    var body: some View {
        Form {
            Section("Safety level") {
                Picker("Level", selection: $viewModel.appSettings.safetyLevel) {
                    ForEach(SafetyLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.radioGroup)
                Text(levelDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Always requires your approval") {
                ForEach(alwaysRequireApproval, id: \.self) { item in
                    Label(item, systemImage: "hand.raised.fill")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
                Text("These rules are always active and cannot be disabled.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Always blocked") {
                ForEach(alwaysBlocked, id: \.self) { item in
                    Label(item, systemImage: "xmark.octagon.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
                Text("Sanecode blocks these commands regardless of safety level.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Agent Access") {
                Text("Access modes control what the agent is instructed to do. SafetyPolicy still blocks dangerous actions regardless of access mode.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                ForEach(AgentAccessMode.allCases) { mode in
                    HStack(alignment: .top, spacing: 12) {
                        Text(mode.rawValue)
                            .font(.callout.weight(.semibold))
                            .frame(width: 130, alignment: .leading)
                        Text(mode.shortDescription)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                Button("Save") { viewModel.save() }
            }
        }
        .padding()
    }

    private var levelDescription: String {
        switch viewModel.appSettings.safetyLevel {
        case .strict: return "Strict: Every command requires explicit approval before running."
        case .normal: return "Normal: Approval required for installs, deletions, pushes, and migrations."
        case .fast: return "Fast: Only clearly dangerous commands are blocked. Others run without prompting."
        case .readOnly: return "Read-only: Agent can inspect and plan but cannot run any commands."
        }
    }
}
