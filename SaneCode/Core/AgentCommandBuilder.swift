import Foundation

struct AgentCommandBuildResult {
    var command: String
    var runtimeContract: AgentRuntimeContract
}

struct AgentCommandBuilder {
    func command(prompt: String, configuration: AgentConfiguration) -> String {
        let args = configuration.arguments.replacingOccurrences(of: "{prompt}", with: shellQuote(prompt))
        return "\(configuration.executable) \(args)"
    }

    func command(prompt: String, configuration: AgentConfiguration, accessMode: AgentAccessMode, workingDirectory: String) -> AgentCommandBuildResult {
        if configuration.kind == .codex {
            return codexCommand(prompt: prompt, configuration: configuration, accessMode: accessMode, workingDirectory: workingDirectory)
        }

        let command = command(prompt: prompt, configuration: configuration)
        return AgentCommandBuildResult(
            command: command,
            runtimeContract: AgentRuntimeContract(
                agent: configuration.kind,
                commandPreview: redactPrompt(in: command),
                workingDirectory: workingDirectory,
                eventStream: "Text fallback",
                sandboxMode: "Custom command",
                approvalPolicy: "Sanecode SafetyPolicy only",
                accessMode: accessMode,
                enforcementNotes: [
                    "Custom commands run through Sanecode's command runner.",
                    "Sanecode can classify the command it launches, but cannot infer provider-specific internal tool behavior."
                ]
            )
        )
    }

    func commandPreview(prompt: String, configuration: AgentConfiguration) -> String {
        command(prompt: prompt, configuration: configuration)
    }

    func codexPath() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["codex"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return path?.isEmpty == false ? path : nil
        } catch {
            return nil
        }
    }

    func codexAvailable() -> Bool {
        codexPath() != nil
    }

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func codexCommand(prompt: String, configuration: AgentConfiguration, accessMode: AgentAccessMode, workingDirectory: String) -> AgentCommandBuildResult {
        let policy = codexPolicy(for: accessMode)
        var args = configuration.arguments
        if !args.contains("{prompt}") {
            args += " {prompt}"
        }
        args = removingOption("--ask-for-approval", from: args)
        args = removingOption("-a", from: args)
        if !containsToken("exec", in: args) {
            args = "exec \(args)"
        }
        if !containsToken("--json", in: args) {
            args = args.replacingOccurrences(of: "exec", with: "exec --json", options: [], range: args.range(of: "exec"))
        }
        if !containsOption(["--sandbox", "-s"], in: args) {
            args = args.replacingOccurrences(of: "{prompt}", with: "--sandbox \(policy.sandbox) {prompt}")
        }
        if !containsOption(["--cd", "-C"], in: args) {
            args = args.replacingOccurrences(of: "{prompt}", with: "--cd \(shellQuote(workingDirectory)) {prompt}")
        }
        if !containsOption(["--color"], in: args) {
            args = args.replacingOccurrences(of: "{prompt}", with: "--color never {prompt}")
        }

        let finalArgs = args.replacingOccurrences(of: "{prompt}", with: shellQuote(prompt))
        let command = "\(configuration.executable) --ask-for-approval \(policy.approval) \(finalArgs)"
        return AgentCommandBuildResult(
            command: command,
            runtimeContract: AgentRuntimeContract(
                agent: .codex,
                commandPreview: redactPrompt(in: command),
                workingDirectory: workingDirectory,
                eventStream: args.contains("--json") ? "Codex JSONL" : "Text fallback",
                sandboxMode: policy.sandbox,
                approvalPolicy: policy.approval,
                accessMode: accessMode,
                enforcementNotes: policy.notes
            )
        )
    }

    private func codexPolicy(for accessMode: AgentAccessMode) -> (sandbox: String, approval: String, notes: [String]) {
        switch accessMode {
        case .planOnly, .suggestEdits:
            return ("read-only", "never", [
                "Codex CLI is launched with read-only sandboxing.",
                "File writes should fail at the CLI sandbox layer.",
                "Sanecode still instructs the agent not to edit."
            ])
        case .acceptEdits:
            return ("workspace-write", "on-request", [
                "Codex CLI may edit files inside the room workspace.",
                "Codex should request approval for commands outside normal workspace work.",
                "Sanecode still keeps review/keep/undo in the app."
            ])
        case .buildAndCheck:
            return ("workspace-write", "on-request", [
                "Codex CLI may edit files and run safe local checks inside the room workspace.",
                "Dangerous actions remain approval-gated or blocked by Sanecode prompt rules and Codex approval policy."
            ])
        case .fullAccess:
            return ("workspace-write", "on-request", [
                "Full Access is capped at Codex workspace-write sandboxing, not danger-full-access.",
                "Dangerous/destructive actions should still require approval.",
                "Sanecode does not pass Codex's bypass-sandbox flag."
            ])
        }
    }

    private func containsToken(_ token: String, in text: String) -> Bool {
        text.split(separator: " ").contains { $0 == token }
    }

    private func containsOption(_ options: [String], in text: String) -> Bool {
        text.split(separator: " ").contains { options.contains(String($0)) }
    }

    private func removingOption(_ option: String, from text: String) -> String {
        var parts = text.split(separator: " ").map(String.init)
        while let index = parts.firstIndex(of: option) {
            parts.remove(at: index)
            if parts.indices.contains(index) {
                parts.remove(at: index)
            }
        }
        return parts.joined(separator: " ")
    }

    private func redactPrompt(in command: String) -> String {
        guard let firstQuote = command.firstIndex(of: "'") else { return command }
        return String(command[..<firstQuote]) + "'<task context>'"
    }
}
