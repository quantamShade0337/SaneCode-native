import Foundation

struct ReviewRiskAnalyzer {
    func analyze(room: AgentRoom) -> [ReviewRisk] {
        var risks: [ReviewRisk] = []
        let files = room.changedFiles
        let paths = files.map { $0.path.lowercased() }

        if files.contains(where: { $0.status == .deleted }) {
            risks.append(ReviewRisk(title: "Deleted files", detail: "This room deleted tracked files. Review before keeping changes.", severity: .warning))
        }

        if paths.contains(where: isDependencyFile) {
            risks.append(ReviewRisk(title: "Dependency files changed", detail: "Package or lock files changed. Confirm this was intentional.", severity: .high))
        }

        if paths.contains(where: { $0.contains("migration") || $0.contains("schema") }) {
            risks.append(ReviewRisk(title: "Database-shaped changes", detail: "Schema or migration files may affect persistent data.", severity: .high))
        }

        if room.hadPreExistingChanges {
            risks.append(ReviewRisk(title: "Repo was already dirty", detail: "Some changes may not belong to this room. Sanecode separated them where possible.", severity: .warning))
        }

        if room.verificationRuns.isEmpty {
            risks.append(ReviewRisk(title: "Checks not run", detail: "Run checks before keeping changes.", severity: .info))
        } else if room.verificationRuns.last?.status == .failed {
            risks.append(ReviewRisk(title: "Checks failed", detail: "Fix failed checks before keeping changes.", severity: .high))
        }

        let diff = room.diff.lowercased()
        if diff.contains("api_key") || diff.contains("secret") || diff.contains("password") || diff.contains("token") {
            risks.append(ReviewRisk(title: "Secret-like text", detail: "Diff contains secret-like terms. Review carefully before keeping changes.", severity: .high))
        }

        if diff.contains("forceunwrap") || diff.contains("fatalerror(") || diff.contains("try!") {
            risks.append(ReviewRisk(title: "Runtime failure risk", detail: "Diff may include forceful runtime behavior.", severity: .warning))
        }

        return risks
    }

    private func isDependencyFile(_ path: String) -> Bool {
        ["package.json", "pnpm-lock.yaml", "package-lock.json", "yarn.lock", "bun.lock", "package.swift", "cargo.toml", "go.mod", "requirements.txt", "pyproject.toml"].contains {
            path.hasSuffix($0)
        }
    }
}
