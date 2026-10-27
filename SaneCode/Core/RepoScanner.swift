import Foundation

struct RepoScanner {
    private let git = GitManager()

    func scan(path: String) -> Repository {
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent
        let isGit = git.isGitRepo(path: path)
        let packageManager = detectPackageManager(path: path)
        let framework = detectFramework(path: path)
        let commands = detectCommands(path: path, packageManager: packageManager)
        let changes = isGit ? git.dirtyFiles(path: path) : []

        return Repository(
            name: name,
            path: path,
            branch: isGit ? git.currentBranch(path: path) : nil,
            isGitRepo: isGit,
            packageManager: packageManager,
            framework: framework,
            dirtyFileCount: changes.count,
            remoteURL: isGit ? git.remoteURL(path: path) : nil,
            statusSummary: changes,
            detectedCommands: commands,
            lastOpenedAt: Date()
        )
    }

    func detectPackageManager(path: String) -> String? {
        let fm = FileManager.default
        if fm.fileExists(atPath: "\(path)/pnpm-lock.yaml") { return "pnpm" }
        if fm.fileExists(atPath: "\(path)/bun.lock") || fm.fileExists(atPath: "\(path)/bun.lockb") { return "bun" }
        if fm.fileExists(atPath: "\(path)/yarn.lock") { return "yarn" }
        if fm.fileExists(atPath: "\(path)/package-lock.json") { return "npm" }
        return nil
    }

    func detectFramework(path: String) -> String? {
        let fm = FileManager.default
        if let package = packageJSON(path: path) {
            let text = package.lowercased()
            if text.contains("\"next\"") { return "Next.js" }
            if text.contains("\"vite\"") { return "Vite" }
            if text.contains("\"react\"") { return "React" }
            if text.contains("\"electron\"") { return "Electron" }
            if text.contains("\"tauri\"") { return "Tauri" }
        }
        if fm.fileExists(atPath: "\(path)/Package.swift") { return "Swift Package" }
        if containsExtension(["xcodeproj", "xcworkspace"], path: path) { return "Xcode project" }
        if fm.fileExists(atPath: "\(path)/Cargo.toml") { return "Rust" }
        if fm.fileExists(atPath: "\(path)/pyproject.toml") || fm.fileExists(atPath: "\(path)/requirements.txt") { return "Python" }
        if fm.fileExists(atPath: "\(path)/go.mod") { return "Go" }
        return nil
    }

    func detectCommands(path: String, packageManager: String?) -> [DetectedCommand] {
        var commands: [DetectedCommand] = []
        let scripts = packageScripts(path: path)
        let manager = packageManager ?? "npm"

        for script in ["dev", "build", "test", "lint", "typecheck"] where scripts.contains(script) {
            let command: String
            if manager == "npm" {
                command = script == "test" ? "npm test" : "npm run \(script)"
            } else if manager == "bun", script == "test" {
                command = "bun test"
            } else {
                command = "\(manager) \(script == "test" && manager == "pnpm" ? "test" : "run \(script)")"
            }
            let kind: CommandKind = script == "dev" ? .server : .checks
            commands.append(DetectedCommand(name: script, command: command, kind: kind, isPrimary: script == "build"))
        }

        let fm = FileManager.default
        if fm.fileExists(atPath: "\(path)/Package.swift") {
            commands.append(DetectedCommand(name: "test", command: "swift test", kind: .checks, isPrimary: commands.isEmpty))
        }
        if fm.fileExists(atPath: "\(path)/Cargo.toml") {
            commands.append(DetectedCommand(name: "test", command: "cargo test", kind: .checks, isPrimary: commands.isEmpty))
        }
        if fm.fileExists(atPath: "\(path)/pyproject.toml") || fm.fileExists(atPath: "\(path)/requirements.txt") {
            commands.append(DetectedCommand(name: "test", command: "pytest", kind: .checks, isPrimary: commands.isEmpty))
        }
        if fm.fileExists(atPath: "\(path)/go.mod") {
            commands.append(DetectedCommand(name: "test", command: "go test ./...", kind: .checks, isPrimary: commands.isEmpty))
        }
        if containsExtension(["xcodeproj", "xcworkspace"], path: path) {
            commands.append(DetectedCommand(name: "build", command: "xcodebuild", kind: .checks, isPrimary: commands.isEmpty))
        }
        return commands
    }

    private func packageJSON(path: String) -> String? {
        try? String(contentsOfFile: "\(path)/package.json", encoding: .utf8)
    }

    private func packageScripts(path: String) -> Set<String> {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: "\(path)/package.json")),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let scripts = json["scripts"] as? [String: Any]
        else { return [] }
        return Set(scripts.keys)
    }

    private func containsExtension(_ extensions: [String], path: String) -> Bool {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: path) else { return false }
        return contents.contains { item in
            extensions.contains(URL(fileURLWithPath: item).pathExtension)
        }
    }
}
