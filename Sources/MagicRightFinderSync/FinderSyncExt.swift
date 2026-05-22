import Cocoa
import FinderSync

@objc(FinderSyncExt)
final class FinderSyncExt: FIFinderSync {
    private struct Service {
        let title: String
        let filename: String
        let symbol: String
        let allowsEmpty: Bool
    }

    private let services: [Service] = [
        Service(title: "生成字幕", filename: "gen_subtitles.sh", symbol: "", allowsEmpty: false),
        Service(title: "新建文本文件", filename: "new_txt.sh", symbol: "", allowsEmpty: false),
        Service(title: "新建 Markdown 文件", filename: "new_md.sh", symbol: "", allowsEmpty: false),
        Service(title: "新建 Word 文档", filename: "new_docx.sh", symbol: "", allowsEmpty: false),
        Service(title: "用 Ghostty 打开", filename: "open_ghostty.sh", symbol: "", allowsEmpty: false),
        Service(title: "用 VS Code 打开", filename: "open_vscode.sh", symbol: "", allowsEmpty: false),
        Service(title: "提交并推送当前仓库", filename: "git_commit_push.sh", symbol: "", allowsEmpty: false),
        Service(title: "复制路径", filename: "copy_path.sh", symbol: "", allowsEmpty: false),
        Service(title: "剪切", filename: "cut_items.sh", symbol: "", allowsEmpty: true),
        Service(title: "粘贴", filename: "paste_cut_items.sh", symbol: "", allowsEmpty: false)
    ]

    private static let logQueue = DispatchQueue(label: "local.elidev.MagicRight.findersync.log")
    private static let logMaxBytes: UInt64 = 1 * 1024 * 1024

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")
        let submenu = NSMenu(title: "MagicRight")

        let appearance = NSAppearance.currentDrawing()
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let tint: NSColor = isDark ? .white : .black

        for (idx, service) in services.enumerated() {
            let item = NSMenuItem(
                title: service.title,
                action: #selector(runScript(_:)),
                keyEquivalent: ""
            )
            item.tag = idx
            if !service.symbol.isEmpty, let image = tintedSymbol(service.symbol, color: tint) {
                item.image = image
            }
            submenu.addItem(item)
        }

        let parent = NSMenuItem(title: "MagicRight", action: nil, keyEquivalent: "")
        if let image = tintedSymbol("sparkles", color: tint) {
            parent.image = image
        }
        parent.submenu = submenu
        menu.addItem(parent)
        return menu
    }

    private func tintedSymbol(_ name: String, color: NSColor) -> NSImage? {
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil) else {
            return nil
        }
        let size = NSSize(width: 16, height: 16)
        return NSImage(size: size, flipped: false) { rect in
            symbol.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }

    private static func debugLog(_ message: String) {
        NSLog("[MagicRight] \(message)")
        let logPath = ("~/Library/Logs/magicright-findersync.log" as NSString)
            .expandingTildeInPath
        let line = "[\(Date())] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        logQueue.async { [maxBytes = logMaxBytes] in
            let fileManager = FileManager.default
            if let attrs = try? fileManager.attributesOfItem(atPath: logPath),
               let size = attrs[.size] as? UInt64,
               size > maxBytes {
                let rotated = logPath + ".1"
                try? fileManager.removeItem(atPath: rotated)
                try? fileManager.moveItem(atPath: logPath, toPath: rotated)
            }

            if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                defer { try? fileHandle.close() }
                _ = try? fileHandle.seekToEnd()
                try? fileHandle.write(contentsOf: data)
            } else {
                try? data.write(to: URL(fileURLWithPath: logPath))
            }
        }
    }

    @objc private func runScript(_ sender: NSMenuItem) {
        Self.debugLog("runScript fired: \(sender.title) tag=\(sender.tag)")
        guard sender.tag >= 0 && sender.tag < services.count else {
            Self.debugLog("tag out of range")
            return
        }

        let service = services[sender.tag]
        let controller = FIFinderSyncController.default()
        let selected = controller.selectedItemURLs() ?? []

        var targets: [String] = []
        if !selected.isEmpty {
            targets = selected.map(\.path)
        } else if !service.allowsEmpty, let target = controller.targetedURL() {
            targets = [target.path]
        }
        Self.debugLog("targets: \(targets)")

        guard !targets.isEmpty || service.allowsEmpty else {
            Self.debugLog("no target")
            return
        }

        do {
            let scriptsURL = try FileManager.default.url(
                for: .applicationScriptsDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let scriptURL = scriptsURL.appendingPathComponent(service.filename)
            Self.debugLog("scriptURL: \(scriptURL.path)")
            let task = try NSUserUnixTask(url: scriptURL)
            task.execute(withArguments: targets) { error in
                if let error {
                    Self.debugLog("script error: \(error)")
                } else {
                    Self.debugLog("script ok")
                }
            }
        } catch {
            Self.debugLog("run failed: \(error)")
        }
    }
}
