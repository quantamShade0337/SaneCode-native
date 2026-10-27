import AppKit
import Combine
import Foundation

final class TerminalViewModel: ObservableObject {
    @Published var selectedTerminalTab: CommandKind = .user
    @Published var userCommand = ""
    @Published var userOutput = ""
    @Published var agentOutput = ""
    @Published var checksOutput = ""
    @Published var serverOutput = ""
    @Published var isRunning = false
    @Published var commandHistory: [String] = []

    private let runner = ShellRunner()
    private let ptySession = PTYTerminalSession()
    private var ptyWorkingDirectory: String?
    private var isUsingPTY = false

    func append(_ text: String, kind: CommandKind) {
        switch kind {
        case .user: userOutput += text
        case .agent: agentOutput += text
        case .checks: checksOutput += text
        case .server: serverOutput += text
        }
    }

    func output(for kind: CommandKind) -> String {
        switch kind {
        case .user: userOutput
        case .agent: agentOutput
        case .checks: checksOutput
        case .server: serverOutput
        }
    }

    func runUserCommand(in path: String) {
        let command = userCommand
        guard !command.isEmpty else { return }
        commandHistory.append(command.trimmingCharacters(in: .whitespacesAndNewlines))
        userCommand = ""
        selectedTerminalTab = .user

        if startPTYIfNeeded(in: path) {
            ptySession.write(command + "\n")
        } else {
            Task {
                isRunning = true
                _ = await runner.run(command, in: path, onOutput: { [weak self] text, kind in
                    self?.append(text, kind: kind)
                }, kind: .user)
                isRunning = false
            }
        }
    }

    func run(_ command: String, in path: String, kind: CommandKind) async -> Int32 {
        await run(command, in: path, kind: kind, onChunk: nil)
    }

    func run(_ command: String, in path: String, kind: CommandKind, onChunk: ((String) -> Void)?) async -> Int32 {
        selectedTerminalTab = kind
        isRunning = true
        let exit = await runner.run(command, in: path, onOutput: { [weak self] text, kind in
            self?.append(text, kind: kind)
            onChunk?(text)
        }, kind: kind)
        isRunning = false
        return exit
    }

    func cancelCurrentCommand() {
        if selectedTerminalTab == .user, isUsingPTY {
            ptySession.interrupt()
        } else {
            runner.cancel()
        }
        isRunning = false
    }

    func clearOutput() {
        switch selectedTerminalTab {
        case .user: userOutput = ""
        case .agent: agentOutput = ""
        case .checks: checksOutput = ""
        case .server: serverOutput = ""
        }
    }

    func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output(for: selectedTerminalTab), forType: .string)
    }

    @discardableResult
    func startPTYIfNeeded(in path: String) -> Bool {
        if isUsingPTY, ptyWorkingDirectory == path {
            return true
        }

        if isUsingPTY {
            ptySession.stop()
            isUsingPTY = false
            ptyWorkingDirectory = nil
        }

        do {
            try ptySession.start(in: path) { [weak self] text in
                self?.append(text, kind: .user)
            }
            ptyWorkingDirectory = path
            isUsingPTY = true
            isRunning = true
            return true
        } catch {
            append("PTY shell unavailable. Falling back to command runner: \(error.localizedDescription)\n", kind: .user)
            isUsingPTY = false
            ptyWorkingDirectory = nil
            return false
        }
    }

    func stopMineSession() {
        ptySession.stop()
        isUsingPTY = false
        ptyWorkingDirectory = nil
        isRunning = false
    }
}
