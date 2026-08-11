import AppKit
import Foundation
final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let fuckcc: String
    let home = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".fuckcc").path
    override init() {
        let candidates = [
            NSHomeDirectory() + "/.local/bin/fuckcc",
            NSHomeDirectory() + "/desktop/fuckcc/fuckcc",
            NSHomeDirectory() + "/Desktop/fuckcc/fuckcc",
            "/usr/local/bin/fuckcc"
        ]
        fuckcc = candidates.first { FileManager.default.isExecutableFile(atPath: $0) } ?? "fuckcc"
        super.init()
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.title = "✈︎"
            btn.toolTip = "fuckcc — Claude 地区伪装"
        }
        rebuildMenu()
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.rebuildMenu()
        }
    }
    func currentRegion() -> String {
        let p = home + "/current_region"
        if let s = try? String(contentsOfFile: p, encoding: .utf8) {
            return s.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "us-west"
    }
    func rebuildMenu() {
        let menu = NSMenu()
        let cur = currentRegion()
        menu.addItem(NSMenuItem(title: "当前: \(cur)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let regions: [(String, String)] = [
            ("us-west", "美国西部"),
            ("us-east", "美国东部"),
            ("us-central", "美国中部"),
            ("jp", "日本"),
            ("sg", "新加坡"),
            ("tw", "台湾"),
            ("hk", "香港"),
            ("kr", "韩国"),
            ("uk", "英国"),
            ("de", "德国"),
            ("au", "澳大利亚"),
            ("ca", "加拿大"),
        ]
        for (id, name) in regions {
            let title = (id == cur ? "✓ " : "  ") + "\(name) (\(id))"
            let item = NSMenuItem(title: title, action: #selector(switchRegion(_:)), keyEquivalent: "")
            item.representedObject = id
            item.target = self
            menu.addItem(item)
        }
        menu.addItem(NSMenuItem.separator())
        let run = NSMenuItem(title: "启动 Claude (伪装)", action: #selector(runClaude), keyEquivalent: "r")
        run.target = self
        menu.addItem(run)
        let probe = NSMenuItem(title: "探针自检", action: #selector(runProbe), keyEquivalent: "p")
        probe.target = self
        menu.addItem(probe)
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "退出菜单栏", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem.menu = menu
        if let btn = statusItem.button {
            btn.title = "✈︎\(cur.prefix(2))"
        }
    }
    @objc func switchRegion(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: fuckcc)
        task.arguments = ["use", id]
        try? task.run()
        task.waitUntilExit()
        rebuildMenu()
        notify("fuckcc", "已切换伪装 → \(id)")
    }
    @objc func runClaude() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        let script = """
        tell application "Terminal"
          do script "\(fuckcc) run"
          activate
        end tell
        """
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
    }
    @objc func runProbe() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: fuckcc)
        task.arguments = ["probe"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: data, encoding: .utf8) ?? ""
        notify("fuckcc probe", String(out.suffix(200)))
    }
    func notify(_ title: String, _ body: String) {
        let n = NSUserNotification()
        n.title = title
        n.informativeText = body
        NSUserNotificationCenter.default.deliver(n)
    }
}
let app = NSApplication.shared
let del = AppDelegate()
app.delegate = del
app.setActivationPolicy(.accessory)
app.run()
