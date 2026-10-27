import Foundation

struct CodeDiagnostic: Identifiable, Equatable {
    var id: String { "\(path):\(line):\(message)" }
    var path: String
    var line: Int
    var severity: ReviewRiskSeverity
    var message: String
}

struct CodeSymbol: Identifiable, Equatable {
    var id: String { "\(path):\(line):\(name)" }
    var name: String
    var kind: String
    var path: String
    var line: Int
}

struct CodeIntelligenceReport: Equatable {
    var diagnostics: [CodeDiagnostic]
    var symbols: [CodeSymbol]
}

struct CodeIntelligenceScanner {
    private let includedExtensions: Set<String> = ["swift", "js", "jsx", "ts", "tsx", "py", "go", "rs", "java", "kt", "m", "mm", "h", "cpp", "c", "rb"]
    private let excludedFolders: Set<String> = ["node_modules", ".git", ".next", "dist", "build", "DerivedData", "vendor", ".venv", "__pycache__"]

    func scan(rootPath: String, limit: Int = 400) -> CodeIntelligenceReport {
        let root = URL(fileURLWithPath: rootPath)
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return CodeIntelligenceReport(diagnostics: [], symbols: [])
        }

        var diagnostics: [CodeDiagnostic] = []
        var symbols: [CodeSymbol] = []
        var scanned = 0

        for case let url as URL in enumerator {
            if excludedFolders.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }
            guard includedExtensions.contains(url.pathExtension.lowercased()), scanned < limit else { continue }
            scanned += 1
            let relative = url.path.replacingOccurrences(of: root.path + "/", with: "")
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            analyze(text: text, path: relative, diagnostics: &diagnostics, symbols: &symbols)
        }

        return CodeIntelligenceReport(diagnostics: Array(diagnostics.prefix(80)), symbols: Array(symbols.prefix(160)))
    }

    private func analyze(text: String, path: String, diagnostics: inout [CodeDiagnostic], symbols: inout [CodeSymbol]) {
        for (offset, line) in text.components(separatedBy: .newlines).enumerated() {
            let number = offset + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lower = trimmed.lowercased()

            if lower.contains("todo") || lower.contains("fixme") {
                diagnostics.append(CodeDiagnostic(path: path, line: number, severity: .info, message: "TODO/FIXME marker"))
            }
            if trimmed.contains("fatalError(") || trimmed.contains("try!") || trimmed.contains("as!") {
                diagnostics.append(CodeDiagnostic(path: path, line: number, severity: .warning, message: "Forceful runtime operation"))
            }
            if path.hasSuffix(".swift"), trimmed.contains("!") && !trimmed.hasPrefix("//") && !trimmed.contains("!=") {
                diagnostics.append(CodeDiagnostic(path: path, line: number, severity: .info, message: "Possible force unwrap"))
            }

            if let symbol = symbol(in: trimmed, path: path, line: number) {
                symbols.append(symbol)
            }
        }
    }

    private func symbol(in line: String, path: String, line number: Int) -> CodeSymbol? {
        let patterns: [(String, String)] = [
            (#"(?:public\s+|private\s+|internal\s+|final\s+|open\s+)*class\s+([A-Za-z_][A-Za-z0-9_]*)"#, "class"),
            (#"(?:public\s+|private\s+|internal\s+)*struct\s+([A-Za-z_][A-Za-z0-9_]*)"#, "struct"),
            (#"(?:public\s+|private\s+|internal\s+)*enum\s+([A-Za-z_][A-Za-z0-9_]*)"#, "enum"),
            (#"(?:public\s+|private\s+|internal\s+)*func\s+([A-Za-z_][A-Za-z0-9_]*)"#, "function"),
            (#"(?:export\s+)?(?:async\s+)?function\s+([A-Za-z_][A-Za-z0-9_]*)"#, "function"),
            (#"(?:const|let|var)\s+([A-Za-z_][A-Za-z0-9_]*)\s*="#, "binding")
        ]

        for (pattern, kind) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: line)
            else { continue }
            return CodeSymbol(name: String(line[range]), kind: kind, path: path, line: number)
        }
        return nil
    }
}
