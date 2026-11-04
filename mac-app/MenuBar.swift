import AppKit
import Foundation

@main
@MainActor
struct CourseMenuApp {
    private static let controller = CourseMenuController()

    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        application.delegate = controller
        application.run()
    }
}

@MainActor
final class CourseMenuController: NSObject, NSApplicationDelegate {
    private enum Operation {
        case idle
        case quitting
        case uninstalling
    }

    private let dataDirectory: URL = {
        if let path = ProcessInfo.processInfo.environment["TLA_COURSE_DATA_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/TLA+ Course", isDirectory: true)
    }()
    private var statusItem: NSStatusItem?
    private var openItem: NSMenuItem?
    private var uninstallItem: NSMenuItem?
    private var quitItem: NSMenuItem?
    private var openingTask: Task<Void, Never>?
    private var launcherProcess: Process?
    private var operation = Operation.idle
    private var permitsTermination = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMenu()
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--menu-state") {
            reportMenuState()
            permitsTermination = true
            NSApplication.shared.terminate(nil)
            return
        }
        if !arguments.contains("--no-browser") {
            openCourse()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openCourse()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if permitsTermination {
            return .terminateNow
        }
        requestQuit()
        return .terminateCancel
    }

    private func installMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "TLA+"
        item.button?.toolTip = "TLA+ Course"
        item.button?.setAccessibilityLabel("TLA+ Course")
        let menu = NSMenu()
        menu.autoenablesItems = false
        let open = NSMenuItem(title: "Open Course", action: #selector(openCourse), keyEquivalent: "o")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())
        let uninstall = NSMenuItem(title: "Uninstall…", action: #selector(uninstallCourse), keyEquivalent: "")
        uninstall.target = self
        menu.addItem(uninstall)
        let quit = NSMenuItem(title: "Quit TLA+ Course", action: #selector(requestQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        item.isVisible = true
        statusItem = item
        openItem = open
        uninstallItem = uninstall
        quitItem = quit
    }

    @objc private func openCourse() {
        guard operation == .idle, openingTask == nil else { return }
        openingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                openingTask = nil
                updateMenuAvailability()
            }
            do {
                try await runLauncher()
            } catch {
                showError("The course could not open.", detail: "Rebuild TLA+ Course to restore its launcher.\n\n\(error.localizedDescription)")
            }
        }
        updateMenuAvailability()
    }

    private func runLauncher() async throws {
        let executable = Bundle.main.bundleURL
            .appendingPathComponent("Contents/MacOS/course-launcher", isDirectory: false)
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: executable.path])
        }
        let process = Process()
        process.executableURL = executable
        process.environment = ProcessInfo.processInfo.environment
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        launcherProcess = process
        defer { launcherProcess = nil }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            process.terminationHandler = { _ in
                continuation.resume()
            }
            do {
                try process.run()
            } catch {
                process.terminationHandler = nil
                continuation.resume(throwing: error)
            }
        }
        // The Rust launcher presents its own native startup/browser errors.
    }

    @objc private func requestQuit() {
        guard operation == .idle else { return }
        operation = .quitting
        updateMenuAvailability()
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let openingTask {
                await openingTask.value
            }
            await stopService()
            permitsTermination = true
            NSApplication.shared.terminate(nil)
        }
    }

    @objc private func uninstallCourse() {
        guard operation == .idle else { return }
        operation = .uninstalling
        updateMenuAvailability()
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let openingTask {
                await openingTask.value
            }
            let removed = await UninstallCoordinator.begin(
                app: Bundle.main.bundleURL,
                dataDirectory: dataDirectory
            )
            if removed {
                permitsTermination = true
                NSApplication.shared.terminate(nil)
            } else {
                operation = .idle
                updateMenuAvailability()
            }
        }
    }

    private func updateMenuAvailability() {
        let idle = operation == .idle
        openItem?.isEnabled = idle && openingTask == nil
        uninstallItem?.isEnabled = idle
        quitItem?.isEnabled = idle
    }

    private func stopService() async {
        guard let base = currentServerURL() else { return }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 2
        configuration.timeoutIntervalForResource = 2
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: base.appendingPathComponent("shutdown"))
        request.httpMethod = "POST"
        request.timeoutInterval = 2
        request.setValue("http://127.0.0.1:49731", forHTTPHeaderField: "Origin")
        request.httpBody = Data()
        _ = try? await session.data(for: request)
    }

    private func currentServerURL() -> URL? {
        let file = dataDirectory.appendingPathComponent("server-url")
        guard let handle = try? FileHandle(forReadingFrom: file) else { return nil }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 258),
              let text = String(data: data, encoding: .utf8) else { return nil }
        let address = text.trimmingCharacters(in: .newlines)
        let prefix = "http://127.0.0.1:49731/"
        guard address.utf8.count <= 256, address.hasPrefix(prefix), address.hasSuffix("/") else { return nil }
        let token = address.dropFirst(prefix.count).dropLast()
        guard !token.isEmpty,
              token.utf8.allSatisfy({ byte in
                  (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122)
                      || (byte >= 48 && byte <= 57) || byte == 45 || byte == 95
              }) else { return nil }
        return URL(string: address)
    }

    private func reportMenuState() {
        let titles = statusItem?.menu?.items.filter { !$0.isSeparatorItem }.map(\.title) ?? []
        let state: [String: Any] = ["menuTitles": titles, "hasStatusItem": statusItem != nil]
        guard var data = try? JSONSerialization.data(withJSONObject: state, options: [.sortedKeys]) else { return }
        data.append(0x0a)
        FileHandle.standardOutput.write(data)
    }

    private func showError(_ message: String, detail: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.informativeText = detail
        alert.addButton(withTitle: "OK")
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
