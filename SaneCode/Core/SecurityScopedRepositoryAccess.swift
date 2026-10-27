import Foundation

struct SecurityScopedRepositoryAccess {
    enum AccessError: LocalizedError {
        case missingBookmark
        case couldNotStartAccess

        var errorDescription: String? {
            switch self {
            case .missingBookmark:
                "Sanecode needs you to reselect this folder before it can access it."
            case .couldNotStartAccess:
                "macOS did not grant access to this folder. Reselect the repository and try again."
            }
        }
    }

    func createBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    func resolveBookmark(_ data: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return (url, isStale)
    }

    func startAccessing(_ url: URL) throws -> Bool {
        let didStart = url.startAccessingSecurityScopedResource()
        guard didStart else { throw AccessError.couldNotStartAccess }
        return didStart
    }

    func stopAccessing(_ url: URL?) {
        url?.stopAccessingSecurityScopedResource()
    }

    func restore(_ repository: Repository) -> Repository {
        var updated = repository
        guard let bookmark = repository.securityScopedBookmark else {
            updated.accessErrorMessage = AccessError.missingBookmark.localizedDescription
            return updated
        }

        do {
            let resolved = try resolveBookmark(bookmark)
            updated.path = resolved.url.path
            updated.bookmarkIsStale = resolved.isStale
            updated.accessErrorMessage = nil
        } catch {
            updated.accessErrorMessage = error.localizedDescription
        }
        return updated
    }
}
