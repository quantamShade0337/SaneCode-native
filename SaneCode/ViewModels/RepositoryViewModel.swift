import AppKit
import Combine
import Foundation

final class RepositoryViewModel: ObservableObject {
    @Published var repository: Repository
    private let scanner = RepoScanner()

    init(repository: Repository) {
        self.repository = repository
    }

    func refreshStatus() {
        repository = scanner.scan(path: repository.path)
    }

    func openInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: repository.path)])
    }

    func openInTerminal() {
        NSWorkspace.shared.open(URL(fileURLWithPath: repository.path))
    }
}
