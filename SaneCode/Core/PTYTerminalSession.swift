import Combine
import Darwin
import Foundation

final class PTYTerminalSession: ObservableObject {
    @Published private(set) var isRunning = false

    private var process: Process?
    private var masterFile: FileHandle?
    private var masterFD: Int32 = -1

    func start(in workingDirectory: String, onOutput: @escaping @MainActor (String) -> Void) throws {
        guard process?.isRunning != true else { return }

        var master: Int32 = -1
        var slave: Int32 = -1
        guard openpty(&master, &slave, nil, nil, nil) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }

        let shell = Self.defaultShell()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-l"]
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        process.environment = ProcessInfo.processInfo.environment.merging([
            "TERM": "xterm-256color",
            "SANECODE_TERMINAL": "1"
        ]) { _, new in new }

        let slaveFile = FileHandle(fileDescriptor: slave, closeOnDealloc: true)
        process.standardInput = slaveFile
        process.standardOutput = slaveFile
        process.standardError = slaveFile

        masterFD = master
        masterFile = FileHandle(fileDescriptor: master, closeOnDealloc: true)
        self.process = process

        masterFile?.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in onOutput(text) }
        }

        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.isRunning = false
                self?.masterFile?.readabilityHandler = nil
            }
        }

        do {
            try process.run()
            isRunning = true
            try? slaveFile.close()
        } catch {
            masterFile?.readabilityHandler = nil
            try? slaveFile.close()
            try? masterFile?.close()
            masterFD = -1
            throw error
        }
    }

    func write(_ text: String) {
        guard masterFD >= 0, let data = text.data(using: .utf8) else { return }
        data.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return }
            _ = Darwin.write(masterFD, base, data.count)
        }
    }

    func interrupt() {
        write("\u{03}")
    }

    func stop() {
        masterFile?.readabilityHandler = nil
        process?.terminate()
        try? masterFile?.close()
        masterFile = nil
        masterFD = -1
        isRunning = false
    }

    private static func defaultShell() -> String {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        return FileManager.default.fileExists(atPath: shell) ? shell : "/bin/zsh"
    }

    deinit {
        stop()
    }
}
