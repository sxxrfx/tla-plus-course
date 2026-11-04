import AppKit
import Foundation

struct UninstallEntry: Codable {
    let relativePath: String
}

struct UninstallManifest: Codable {
    let version: Int
    let sourceRoot: String
    let sources: [UninstallEntry]
}

struct UninstallPlan {
    let app: URL
    let dataDirectory: URL
    let sourceFiles: [URL]

    static func make(app: URL, dataDirectory: URL) throws -> UninstallPlan {
        let fm = FileManager.default
        let app = app.standardizedFileURL
        guard app.pathExtension == "app",
              let bundle = Bundle(url: app),
              bundle.bundleIdentifier == "local.tla.course",
              try !isSymlink(app) else {
            throw UninstallFailure.invalidApp
        }
        let data = dataDirectory.standardizedFileURL
        let home = fm.homeDirectoryForCurrentUser.standardizedFileURL
        guard data.path != "/", data != home, data != app.deletingLastPathComponent(),
              !app.path.hasPrefix(data.path + "/"),
              try !isSymlink(data) else {
            throw UninstallFailure.invalidDataFolder
        }
        let manifestURL = app.appendingPathComponent("Contents/Resources/uninstall-files.json")
        var sourceFiles: [URL] = []
        if fm.fileExists(atPath: manifestURL.path) {
            let bytes = try Data(contentsOf: manifestURL)
            guard bytes.count <= 16384 else { throw UninstallFailure.invalidManifest }
            let manifest = try JSONDecoder().decode(UninstallManifest.self, from: bytes)
            let root = URL(fileURLWithPath: manifest.sourceRoot, isDirectory: true).standardizedFileURL
            let allowed = Set(["tla-plus-course.html", "mac-app", "course", "docs", "README.md", "LICENSE", ".gitignore", "output/tla-ticket.html"])
            guard manifest.version == 1, root.path != "/", root != home,
                  manifest.sourceRoot.hasPrefix("/"), manifest.sources.count <= allowed.count else {
                throw UninstallFailure.invalidManifest
            }
            var seen = Set<String>()
            for entry in manifest.sources {
                guard allowed.contains(entry.relativePath), seen.insert(entry.relativePath).inserted else {
                    throw UninstallFailure.invalidManifest
                }
                let url = root.appendingPathComponent(entry.relativePath).standardizedFileURL
                guard url.path.hasPrefix(root.path + "/"), url != app, url != data,
                      try !isSymlink(url) else { throw UninstallFailure.invalidManifest }
                if fm.fileExists(atPath: url.path) { sourceFiles.append(url) }
            }
        }
        return UninstallPlan(app: app, dataDirectory: data, sourceFiles: sourceFiles)
    }

    func targets(includeSources: Bool) -> [URL] {
        let candidates = (includeSources ? sourceFiles : []) + [dataDirectory, app]
        return candidates.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    // rmdir only succeeds on an empty folder, so unrelated files are never touched.
    func removeEmptyOutputFolder() {
        guard let ticket = sourceFiles.first(where: { $0.lastPathComponent == "tla-ticket.html" }) else { return }
        rmdir(ticket.deletingLastPathComponent().path)
    }

    var summary: String {
        let always = targets(includeSources: false).map(\.path).joined(separator: "\n")
        guard !sourceFiles.isEmpty else { return always }
        let sources = sourceFiles.map(\.path).joined(separator: "\n")
        return "Always removed:\n\(always)\n\nRemoved if the box above is ticked:\n\(sources)"
    }

    static func isSymlink(_ url: URL) throws -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        return try url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true
    }
}

enum UninstallFailure: LocalizedError {
    case invalidApp, invalidDataFolder, invalidManifest, serverStillRunning
    var errorDescription: String? {
        switch self {
        case .invalidApp: "The app could not verify its installation. No files were removed."
        case .invalidDataFolder: "The saved-data folder could not be verified. No files were removed."
        case .invalidManifest: "The course source-file list could not be verified. No files were removed."
        case .serverStillRunning: "The course server has not stopped. Close the course tabs and try Uninstall again. No files were removed."
        }
    }
}

@MainActor
final class UninstallCoordinator {
    static func begin(app: URL, dataDirectory: URL) async -> Bool {
        do {
            let plan = try UninstallPlan.make(app: app, dataDirectory: dataDirectory)
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Uninstall TLA+ Course?"
            alert.informativeText = "Moves the app, saved progress and notes to Trash. Open course tabs clear their browser-saved progress."
            alert.addButton(withTitle: "Cancel")
            let remove = alert.addButton(withTitle: "Uninstall")
            remove.hasDestructiveAction = true
            remove.keyEquivalent = ""
            alert.buttons[0].keyEquivalent = "\r"

            let view = NSView(frame: NSRect(x: 0, y: 0, width: 470, height: 190))
            let includeSources = NSButton(checkboxWithTitle: "Also remove course source files", target: nil, action: nil)
            includeSources.state = .on
            includeSources.frame = NSRect(x: 0, y: 162, width: 470, height: 24)
            includeSources.isHidden = plan.sourceFiles.isEmpty
            view.addSubview(includeSources)
            let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 470, height: 150))
            scroll.hasVerticalScroller = true
            scroll.borderType = .bezelBorder
            let text = NSTextView(frame: NSRect(x: 0, y: 0, width: 450, height: 150))
            text.isEditable = false
            text.isSelectable = true
            text.font = .systemFont(ofSize: 12)
            text.textContainerInset = NSSize(width: 8, height: 8)
            text.string = plan.summary
            text.setAccessibilityLabel("Files and folders removed by uninstall")
            scroll.documentView = text
            view.addSubview(scroll)
            alert.accessoryView = view
            NSApplication.shared.activate()
            guard alert.runModal() == .alertSecondButtonReturn else { return false }

            try await stopServer(dataDirectory: dataDirectory)
            let sourcesRemoved = includeSources.state == .on
            let trashedApp = try moveToTrash(plan.targets(includeSources: sourcesRemoved))[plan.app]
            if sourcesRemoved { plan.removeEmptyOutputFolder() }
            if let trashedApp { unregister(trashedApp) }
            return true
        } catch {
            let alert = NSAlert()
            alert.messageText = "Uninstall could not finish"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return false
        }
    }

    static func serverURL(in dataDirectory: URL) -> URL? {
        let file = dataDirectory.appendingPathComponent("server-url")
        guard let bytes = try? Data(contentsOf: file), bytes.count <= 256,
              let value = String(data: bytes, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: value), url.scheme == "http", url.host == "127.0.0.1", url.port == 49731,
              url.query == nil, url.fragment == nil else { return nil }
        let token = url.path.split(separator: "/")
        guard token.count == 1, token[0].count == 64, token[0].allSatisfy(\.isHexDigit) else { return nil }
        return url
    }

    private static func probe(_ url: URL) async -> Bool {
        var request = URLRequest(url: url.appendingPathComponent("progress"))
        request.timeoutInterval = 1
        request.cachePolicy = .reloadIgnoringLocalCacheData
        guard let (_, response) = try? await URLSession.shared.data(for: request) else { return false }
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    static func stopServer(dataDirectory: URL) async throws {
        guard let url = serverURL(in: dataDirectory), await probe(url) else { return }
        var request = URLRequest(url: url.appendingPathComponent("uninstall"))
        request.httpMethod = "POST"
        request.timeoutInterval = 2
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw UninstallFailure.serverStillRunning
        }
        for _ in 0..<15 {
            try await Task.sleep(for: .milliseconds(150))
            if !(await probe(url)) { return }
        }
        throw UninstallFailure.serverStillRunning
    }

    // Put the app last. If any move fails, restore earlier moves before returning an error.
    @discardableResult
    static func moveToTrash(_ targets: [URL]) throws -> [URL: URL] {
        var moved: [(original: URL, trash: URL)] = []
        do {
            for url in targets {
                var result: NSURL?
                try FileManager.default.trashItem(at: url, resultingItemURL: &result)
                if let result { moved.append((url, result as URL)) }
            }
        } catch {
            for entry in moved.reversed() {
                try? FileManager.default.moveItem(at: entry.trash, to: entry.original)
            }
            throw error
        }
        return Dictionary(uniqueKeysWithValues: moved.map { ($0.original, $0.trash) })
    }

    private static func unregister(_ app: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister")
        process.arguments = ["-u", app.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }
}
