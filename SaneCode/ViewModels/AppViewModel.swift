import AppKit
import Combine
import Foundation

final class AppViewModel: ObservableObject {
    @Published var selectedRepository: Repository?
    @Published var repositories: [Repository] = []
    @Published var rooms: [AgentRoom] = []
    @Published var selectedRoom: AgentRoom?
    @Published var selectedMainTab: MainTab = .work
    @Published var isTerminalDrawerOpen = true
    @Published var showNewRoom = false
    @Published var showCommandPalette = false
    @Published var showSettings = false
    @Published var isScanning = false
    @Published var scanSteps: [String] = []
    @Published var selectedFilePath: String?
    @Published var backendHealthReport: BackendHealthReport?

    let sessionStore = SessionStore()
    let settingsStore: SettingsStore
    let scanner = RepoScanner()
    let git = GitManager()
    let terminalViewModel = TerminalViewModel()
    private let repositoryAccess = SecurityScopedRepositoryAccess()
    private let backendHealthChecker = BackendHealthChecker()
    private var activeSecurityScopedURL: URL?

    @Published var repositoryAccessMessage: String?
    @Published var toastMessage: String?
    @Published var isSidebarVisible = true
    @Published var isRightPanelVisible = true
    private var toastTimer: Timer?

    init() {
        settingsStore = SettingsStore(sessionStore: sessionStore)
        loadState()
    }

    func loadState() {
        let state = sessionStore.load()
        repositories = state.repositories.map { repositoryAccess.restore($0) }
        rooms = state.rooms
        if let first = repositories.first(where: { $0.accessErrorMessage == nil }) {
            selectRestoredRepository(first)
        } else if let first = repositories.first {
            repositoryAccessMessage = first.accessErrorMessage
        }
        saveState()
    }

    func saveState() {
        sessionStore.save(PersistedState(
            repositories: repositories,
            rooms: rooms,
            settings: settingsStore.settings,
            agentConfigurations: settingsStore.agentConfigurations,
            commandHistory: terminalViewModel.commandHistory
        ))
    }

    func showToast(_ message: String) {
        toastTimer?.invalidate()
        toastMessage = message
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.8, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.toastMessage = nil
            }
        }
    }

    func runBackendHealthCheck() {
        backendHealthReport = backendHealthChecker.check(sessionStore: sessionStore, repositories: repositories, rooms: rooms)
    }

    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "sanecode" else { return }
        switch url.host {
        case "run":
            let prompt = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "prompt" })?
                .value ?? ""
            if selectedRoom == nil {
                _ = createRoom(title: prompt.isEmpty ? "CLI task" : String(prompt.prefix(48)), prompt: prompt, select: true)
            } else if var room = selectedRoom {
                room.prompt = prompt
                room.updatedAt = Date()
                updateSelectedRoom(room)
            }
            selectedMainTab = .work
        case "open":
            if let path = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "path" })?
                .value {
                Task { await openRepository(at: path) }
            }
        default:
            break
        }
    }

    func openRepository() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Repository"
        if panel.runModal() == .OK, let url = panel.url {
            Task { await openRepository(fromPanelURL: url) }
        }
    }

    func openRecentRepository(_ repository: Repository) {
        Task { await openRepository(repository) }
    }

    func openRepository(fromPanelURL url: URL) async {
        do {
            let bookmark = try repositoryAccess.createBookmark(for: url)
            await openRepository(at: url.path, bookmark: bookmark)
        } catch {
            repositoryAccessMessage = "Sanecode could not save access to this folder. Reselect it and try again."
            await openRepository(at: url.path, bookmark: nil)
        }
    }

    func openRepository(_ repository: Repository) async {
        var restored = repositoryAccess.restore(repository)
        guard restored.accessErrorMessage == nil, let bookmark = restored.securityScopedBookmark else {
            repositoryAccessMessage = restored.accessErrorMessage ?? "Sanecode needs you to reselect this folder before it can access it."
            selectedRepository = nil
            return
        }

        do {
            let resolved = try repositoryAccess.resolveBookmark(bookmark)
            _ = try repositoryAccess.startAccessing(resolved.url)
            if resolved.isStale {
                restored.securityScopedBookmark = try? repositoryAccess.createBookmark(for: resolved.url)
                restored.bookmarkIsStale = restored.securityScopedBookmark == nil
            }
            repositoryAccess.stopAccessing(resolved.url)
            await openRepository(at: restored.path, bookmark: restored.securityScopedBookmark)
        } catch {
            restored.accessErrorMessage = error.localizedDescription
            repositoryAccessMessage = error.localizedDescription
            selectedRepository = nil
            replaceRepository(restored)
            saveState()
        }
    }

    func openRepository(at path: String, bookmark: Data? = nil) async {
        isScanning = true
        selectedRepository = nil
        scanSteps = ["Scanning repository..."]

        stopRepositoryAccess()
        var accessURL: URL?
        if let bookmark {
            do {
                let resolved = try repositoryAccess.resolveBookmark(bookmark)
                _ = try repositoryAccess.startAccessing(resolved.url)
                accessURL = resolved.url
            } catch {
                isScanning = false
                repositoryAccessMessage = error.localizedDescription
                return
            }
        }

        let repo = scanner.scan(path: path)
        var accessibleRepo = repo
        if let existing = repositories.first(where: { $0.path == repo.path }) {
            accessibleRepo.id = existing.id
        }
        accessibleRepo.securityScopedBookmark = bookmark
        accessibleRepo.accessErrorMessage = nil
        accessibleRepo.bookmarkIsStale = false
        scanSteps.append(repo.isGitRepo ? "Git repository detected" : "This folder is not a Git repository")
        if let branch = repo.branch { scanSteps.append("Branch: \(branch)") }
        if let manager = repo.packageManager { scanSteps.append("Package manager: \(manager)") }
        if let framework = repo.framework { scanSteps.append("Framework: \(framework)") }
        repo.detectedCommands.prefix(5).forEach { scanSteps.append("Command found: \($0.command)") }

        try? await Task.sleep(for: .milliseconds(350))
        repositories.removeAll { $0.path == accessibleRepo.path }
        repositories.insert(accessibleRepo, at: 0)
        activeSecurityScopedURL = accessURL
        selectedRepository = accessibleRepo
        selectedRoom = rooms.first(where: { $0.repositoryID == accessibleRepo.id }) ?? createRoom(title: "Review current changes", prompt: "", select: true)
        isScanning = false
        repositoryAccessMessage = nil
        saveState()
    }

    @discardableResult
    func createRoom(title: String = "New room", prompt: String = "", select: Bool = true) -> AgentRoom? {
        guard let repo = selectedRepository else { return nil }
        var room = AgentRoom(title: title, repositoryID: repo.id, repositoryPath: repo.path, prompt: prompt, agent: settingsStore.settings.defaultAgent)
        room.reasoningLevel = settingsStore.settings.defaultReasoningLevel
        room.accessMode = settingsStore.settings.defaultAccessMode
        room.contextPreset = settingsStore.settings.defaultContextPreset
        room.messages.append(AgentMessage(roomID: room.id, kind: .systemEvent, text: "Room is ready. Describe the work and run the task."))
        rooms.insert(room, at: 0)
        if select {
            selectedRoom = room
            selectedMainTab = .work
        }
        saveState()
        return room
    }

    func updateSelectedRoom(_ room: AgentRoom) {
        selectedRoom = room
        if let index = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[index] = room
        }
        saveState()
    }

    func refreshRepository() {
        guard let repo = selectedRepository else { return }
        guard ensureRepositoryAccess(repo) else { return }
        let refreshed = scanner.scan(path: repo.path)
        var updated = refreshed
        updated.securityScopedBookmark = repo.securityScopedBookmark
        updated.bookmarkIsStale = repo.bookmarkIsStale
        selectedRepository = updated
        if let index = repositories.firstIndex(where: { $0.path == repo.path }) {
            repositories[index] = updated
        }
        saveState()
    }

    func ensureRepositoryAccess(_ repository: Repository) -> Bool {
        if activeSecurityScopedURL?.path == repository.path {
            return true
        }

        guard let bookmark = repository.securityScopedBookmark else {
            repositoryAccessMessage = "Sanecode needs you to reselect this folder before it can access it."
            return false
        }

        do {
            let resolved = try repositoryAccess.resolveBookmark(bookmark)
            _ = try repositoryAccess.startAccessing(resolved.url)
            activeSecurityScopedURL = resolved.url
            if resolved.isStale {
                var updated = repository
                updated.securityScopedBookmark = try? repositoryAccess.createBookmark(for: resolved.url)
                updated.bookmarkIsStale = updated.securityScopedBookmark == nil
                replaceRepository(updated)
            }
            return true
        } catch {
            repositoryAccessMessage = error.localizedDescription
            return false
        }
    }

    func reselectRepositoryForAccess() {
        openRepository()
    }

    func stopRepositoryAccess() {
        repositoryAccess.stopAccessing(activeSecurityScopedURL)
        activeSecurityScopedURL = nil
    }

    private func selectRestoredRepository(_ repository: Repository) {
        guard ensureRepositoryAccess(repository) else { return }
        selectedRepository = repository
        selectedRoom = rooms.first(where: { $0.repositoryID == repository.id })
    }

    private func replaceRepository(_ repository: Repository) {
        if let index = repositories.firstIndex(where: { $0.id == repository.id || $0.path == repository.path }) {
            repositories[index] = repository
        }
    }

    deinit {
        stopRepositoryAccess()
    }

    func executeCommandPaletteAction(_ title: String) {
        switch title {
        case "Open Repository": openRepository()
        case "New Room": showNewRoom = true
        case "Run Checks": selectedMainTab = .changes
        case "Show Changes": selectedMainTab = .changes
        case "Open Preview": selectedMainTab = .preview
        case "Open Terminal": selectedMainTab = .terminal
        case "Open Settings": NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        case "Toggle Terminal Drawer": isTerminalDrawerOpen.toggle()
        default: break
        }
    }
}
