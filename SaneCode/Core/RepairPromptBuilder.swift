import Foundation

struct RepairPromptBuilder {
    func build(room: AgentRoom, repository: Repository, failedCheck: FailedCheck) -> String {
        """
        Fix only the cause of the failed check. Avoid unrelated refactors. Prefer the smallest safe diff.
        Do not introduce new dependencies unless necessary and approved. After fixing, report what changed and which check should be rerun.

        Original user task:
        \(room.prompt)

        Room:
        - Title: \(room.title)
        - Changed files from this room: \(room.changedFiles.map(\.path).joined(separator: ", "))

        Failed command:
        \(failedCheck.command)

        Exit code:
        \(failedCheck.exitCode)

        Useful error excerpt:
        \(failedCheck.errorExcerpt)

        Current diff summary:
        \(room.changeSets.last?.roomChangedFiles.map(\.path).joined(separator: ", ") ?? room.changedFiles.map(\.path).joined(separator: ", "))

        Project:
        - Package manager: \(repository.packageManager ?? "unknown")
        - Framework: \(repository.framework ?? "unknown")
        """
    }
}
