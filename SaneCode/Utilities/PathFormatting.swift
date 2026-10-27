import Foundation

enum PathFormatting {
    static func shortened(_ path: String) -> String {
        path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }
}
