import Combine
import Foundation

final class ShellRunner: ObservableObject {
    private var process: Process?

    var isRunning: Bool {
        process?.isRunning ?? false
    }

    func run(
        _ command: String,
        in workingDirectory: String,
        environment: [String: String] = [:],
        onOutput: @escaping @MainActor (String, CommandKind) -> Void,
        kind: CommandKind
    ) async -> Int32 {
        await MainActor.run {
            onOutput("$ \(command)\n", kind)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        self.process = process

        stdout.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in onOutput(text, kind) }
        }

        stderr.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in onOutput(text, kind) }
        }

        return await withCheckedContinuation { continuation in
            process.terminationHandler = { process in
                stdout.fileHandleForReading.readabilityHandler = nil
                stderr.fileHandleForReading.readabilityHandler = nil
                Task { @MainActor in
                    onOutput("\nCommand finished with exit code \(process.terminationStatus)\n", kind)
                    continuation.resume(returning: process.terminationStatus)
                }
            }

            do {
                try process.run()
            } catch {
                stdout.fileHandleForReading.readabilityHandler = nil
                stderr.fileHandleForReading.readabilityHandler = nil
                Task { @MainActor in
                    onOutput("Could not run command: \(error.localizedDescription)\n", kind)
                    continuation.resume(returning: 127)
                }
            }
        }
    }

    func cancel() {
        process?.terminate()
    }
}
