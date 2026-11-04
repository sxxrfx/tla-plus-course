import Foundation
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true).standardizedFileURL.path
let document: [String: Any] = [
    "version": 1,
    "sourceRoot": root,
    "sources": ["tla-plus-course.html", "mac-app", "course", "docs", "README.md", "LICENSE", ".gitignore", ".github", "output/tla-ticket.html"].map { ["relativePath": $0] }
]
try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
    .write(to: URL(fileURLWithPath: CommandLine.arguments[2]), options: .atomic)
