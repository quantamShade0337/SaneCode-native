import Foundation

struct DiffHunk: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var text: String
}

struct DiffHunkParser {
    func parse(_ diff: String) -> [DiffHunk] {
        var hunks: [DiffHunk] = []
        var currentTitle = "File Header"
        var current: [String] = []

        for line in diff.components(separatedBy: .newlines) {
            if line.hasPrefix("@@") {
                if !current.isEmpty {
                    hunks.append(DiffHunk(title: currentTitle, text: current.joined(separator: "\n")))
                    current.removeAll()
                }
                currentTitle = line
            }
            current.append(line)
        }

        if !current.isEmpty {
            hunks.append(DiffHunk(title: currentTitle, text: current.joined(separator: "\n")))
        }
        return hunks
    }
}
