import Foundation

struct SafetyPolicy {
    var level: SafetyLevel = .normal

    func classify(command: String) -> SafetyClassification {
        let lowered = command.lowercased()
        let blockedPatterns = [
            "rm -rf",
            "sudo",
            "chmod -r",
            "chown -r",
            "git reset --hard",
            "git clean -fd",
            "git push --force",
            "cat .env",
            "less .env",
            "open .env",
            "curl | bash",
            "wget | bash",
            "deploy",
            "db:migrate:prod",
            "migrate production"
        ]

        if level == .readOnly {
            return .blocked(reason: "Read-only safety is enabled.")
        }

        if let pattern = blockedPatterns.first(where: { lowered.contains($0) }) {
            return .blocked(reason: "`\(pattern)` is blocked until Sanecode has explicit destructive-command approval.")
        }

        let approvalPatterns = [
            "pnpm add": ("Dependency install", "This changes package files and may update a lockfile."),
            "npm install": ("Dependency install", "This changes package files and may update a lockfile."),
            "npm i ": ("Dependency install", "This changes package files and may update a lockfile."),
            "yarn add": ("Dependency install", "This changes package files and may update a lockfile."),
            "bun add": ("Dependency install", "This changes package files and may update a lockfile."),
            "git push": ("Git push", "This sends local commits to a remote repository."),
            "rm ": ("File deletion", "This deletes files from the working tree."),
            "migrate": ("Database migration", "This may change database state."),
            "pnpm-lock.yaml": ("Lockfile change", "This may change dependency resolution."),
            "package-lock.json": ("Lockfile change", "This may change dependency resolution."),
            "yarn.lock": ("Lockfile change", "This may change dependency resolution."),
            "bun.lock": ("Lockfile change", "This may change dependency resolution.")
        ]

        if level == .strict {
            return .requiresApproval(reason: "Strict safety is enabled.", risk: "Sanecode asks before running commands that may change files.")
        }

        if level == .normal, let match = approvalPatterns.first(where: { lowered.contains($0.key) }) {
            return .requiresApproval(reason: match.value.0, risk: match.value.1)
        }

        return .allowed
    }
}
