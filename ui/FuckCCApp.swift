import AppKit
import Darwin
import SwiftUI
@main
struct FuckCCAppMain: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var body: some Scene {
    WindowGroup { ContentView() }
      .defaultSize(width: 540, height: 820)
      .windowStyle(.hiddenTitleBar)
  }
}
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ n: Notification) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
    DispatchQueue.main.async { NSApp.windows.forEach { $0.makeKeyAndOrderFront(nil) } }
  }
  func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }
}
enum AppLang: String, CaseIterable, Identifiable {
  case auto, en, zh, ja, ko, de
  var id: String { rawValue }
  var label: String {
    switch self {
    case .auto: return "Auto / 自动"
    case .en: return "English"
    case .zh: return "简体中文"
    case .ja: return "日本語"
    case .ko: return "한국어"
    case .de: return "Deutsch"
    }
  }
  static func resolve(_ pref: AppLang) -> AppLang {
    if pref != .auto { return pref }
    let code = Locale.current.language.languageCode?.identifier ?? "en"
    if code.hasPrefix("zh") { return .zh }
    if code == "ja" { return .ja }
    if code == "ko" { return .ko }
    if code == "de" { return .de }
    return .en
  }
}
struct L10n {
  let lang: AppLang
  init(_ pref: AppLang) { self.lang = AppLang.resolve(pref) }
  private func t(_ en: String, _ zh: String, _ ja: String? = nil, _ ko: String? = nil, _ de: String? = nil) -> String {
    switch lang {
    case .zh: return zh
    case .ja: return ja ?? en
    case .ko: return ko ?? en
    case .de: return de ?? en
    default: return en
    }
  }
  var appSubtitle: String { t("Local camouflage · Free translate · Claude launcher", "本地伪装 · 免费翻译 · Claude 启动器", "ローカル偽装 · 無料翻訳 · Claude起動", "로컬 위장 · 무료 번역 · Claude 실행", "Lokale Tarnung · Kostenlose Übersetzung") }
  var help: String { t("Guide", "使用说明", "使い方", "사용 설명", "Anleitung") }
  var region: String { t("Region", "伪装地区", "地域", "지역", "Region") }
  var mode: String { t("Launch mode", "启动模式", "起動モード", "실행 모드", "Startmodus") }
  var workDir: String { t("Working folder", "工作目录", "作業フォルダ", "작업 폴더", "Arbeitsordner") }
  var pickFolder: String { t("Choose folder…", "选择文件夹…", "フォルダを選択…", "폴더 선택…", "Ordner wählen…") }
  var launchHere: String { t("Launch in current folder", "用当前目录启动", "このフォルダで起動", "현재 폴더에서 실행", "Hier starten") }
  var launchPick: String { t("Choose folder & launch Claude", "选择目录并启动 Claude", "フォルダを選んで Claude 起動", "폴더 선택 후 Claude 실행", "Ordner wählen & Claude starten") }
  var services: String { t("Start services", "启动服务", "サービス起動", "서비스 시작", "Dienste starten") }
  var install: String { t("Full install", "完整安装", "フルインストール", "전체 설치", "Vollinstallation") }
  var translateOn: String { t("Prompt translation", "提示词翻译", "プロンプト翻訳", "프롬프트 번역", "Prompt-Übersetzung") }
  var translateHint: String { t("Any language → selected region language (local free)", "任意语言 → 所选地区语言（本地免费）", "任意言語→選択地域の言語（無料ローカル）", "모든 언어 → 선택 지역 언어(로컬 무료)", "Beliebige Sprache → Regionsprache (lokal, gratis)") }
  var appLang: String { t("App language", "界面语言", "アプリ言語", "앱 언어", "App-Sprache") }
  var log: String { t("Log", "运行日志", "ログ", "로그", "Protokoll") }
  var statusRegion: String { t("Region", "地区", "地域", "지역", "Region") }
  var statusProxy: String { t("Proxy", "反代", "プロキシ", "프록시", "Proxy") }
  var statusTranslate: String { t("Translate", "翻译", "翻訳", "번역", "Übersetzung") }
  var statusMode: String { t("Mode", "模式", "モード", "모드", "Modus") }
  var on: String { t("On", "开", "オン", "켜짐", "An") }
  var off: String { t("Off", "关", "オフ", "꺼짐", "Aus") }
  var running: String { t("Running", "运行中", "稼働中", "실행 중", "Aktiv") }
  var stopped: String { t("Stopped", "未启动", "停止", "중지", "Stopp") }
  var ready: String { t("Ready", "就绪", "準備完了", "준비됨", "Bereit") }
  var notReady: String { t("Not ready", "未就绪", "未準備", "미준비", "Nicht bereit") }
  var guideTeaser: String { t("First time? Open the full guide", "第一次用？打开完整使用教程", "初めて？ガイドを開く", "처음이신가요? 전체 가이드", "Zum ersten Mal? Anleitung öffnen") }
  var noWorkDir: String { t("Not set (picker will show on launch)", "尚未选择（启动时会弹出）", "未設定（起動時に選択）", "미선택(실행 시 선택)", "Nicht gesetzt") }
}
enum Shell {
  static var logURL: URL {
    let d = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".fuckcc")
    try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
    return d.appendingPathComponent("ui.log")
  }
  static func log(_ s: String) {
    let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(s)\n"
    guard let data = line.data(using: .utf8) else { return }
    if FileManager.default.fileExists(atPath: logURL.path), let h = try? FileHandle(forWritingTo: logURL) {
      defer { try? h.close() }; _ = try? h.seekToEnd(); try? h.write(contentsOf: data)
    } else { try? data.write(to: logURL) }
  }
  static func resolveFuckcc() -> String? {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    for c in [home+"/Desktop/fuckcc/fuckcc", home+"/desktop/fuckcc/fuckcc", home+"/.local/bin/fuckcc",
              home+"/.local/share/fuckcc/fuckcc", "/opt/homebrew/bin/fuckcc", "/usr/local/bin/fuckcc"] {
      var isDir: ObjCBool = false
      if FileManager.default.fileExists(atPath: c, isDirectory: &isDir), !isDir.boolValue,
         FileManager.default.isExecutableFile(atPath: c) { return c }
    }
    return nil
  }
  @discardableResult
  static func runFuckcc(_ args: [String], timeout: TimeInterval = 90) -> (Int32, String) {
    guard let bin = resolveFuckcc() else { return (127, "fuckcc not found") }
    log("RUN \(bin) \(args.joined(separator: " "))")
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = [bin] + args
    task.currentDirectoryURL = URL(fileURLWithPath: (bin as NSString).deletingLastPathComponent)
    var env = ProcessInfo.processInfo.environment
    env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + (env["PATH"] ?? "")
    env["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
    env["FUCKCC_HOME"] = FileManager.default.homeDirectoryForCurrentUser.path + "/.fuckcc"
    task.environment = env
    let pipe = Pipe(); task.standardOutput = pipe; task.standardError = pipe
    do { try task.run() } catch { return (1, error.localizedDescription) }
    let g = DispatchGroup(); g.enter()
    DispatchQueue.global().async { task.waitUntilExit(); g.leave() }
    if g.wait(timeout: .now() + timeout) == .timedOut { task.terminate(); return (124, "timeout") }
    let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return (task.terminationStatus, out)
  }
  static func processAlive(_ pid: Int) -> Bool { kill(Int32(pid), 0) == 0 }
  static func httpOK(_ url: String) -> Bool {
    guard let u = URL(string: url) else { return false }
    var req = URLRequest(url: u, timeoutInterval: 1.2); req.httpMethod = "GET"
    let sem = DispatchSemaphore(value: 0); var ok = false
    URLSession.shared.dataTask(with: req) { data, resp, _ in
      if let h = resp as? HTTPURLResponse, (200..<500).contains(h.statusCode) { ok = true }
      else if data != nil { ok = true }
      sem.signal()
    }.resume()
    _ = sem.wait(timeout: .now() + 1.5)
    return ok
  }
  static func pickFolder(start: String?) -> String? {
    let p = NSOpenPanel()
    p.canChooseFiles = false; p.canChooseDirectories = true; p.allowsMultipleSelection = false
    p.canCreateDirectories = true; p.prompt = "OK"; p.message = "Select working directory for Claude Code"
    if let start, FileManager.default.fileExists(atPath: start) {
      p.directoryURL = URL(fileURLWithPath: start)
    } else {
      p.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    }
    return p.runModal() == .OK ? p.url?.path : nil
  }
}
struct RegionItem: Identifiable, Hashable { let id, name, tz: String }
struct LaunchModeItem: Identifiable, Hashable {
  let id, title, subtitle, cliHint: String
}
@MainActor
final class FuckCCModel: ObservableObject {
  @Published var region = "us-west"
  @Published var regions: [RegionItem] = []
  @Published var launchMode = "bypass"
  @Published var workDir = ""
  @Published var translateOn = true
  @Published var hideLevel: Int = 3
  @Published var appLang: AppLang = .auto
  @Published var statusText = "…"
  @Published var detailLog = ""
  @Published var proxyOK = false
  @Published var translateOK = false
  @Published var busy = false
  @Published var banner: String?
  @Published var fuckccPath = ""
  @Published var showHelp = false
  var L: L10n { L10n(appLang) }
  let launchModes: [LaunchModeItem] = [
    .init(id: "bypass", title: "Bypass", subtitle: "Full skip", cliHint: "--dangerously-skip-permissions"),
    .init(id: "manual", title: "Manual", subtitle: "Ask every time", cliHint: "(default)"),
    .init(id: "acceptEdits", title: "Accept Edits", subtitle: "Auto file edits", cliHint: "--permission-mode acceptEdits"),
    .init(id: "auto", title: "Auto", subtitle: "Auto permissions", cliHint: "--permission-mode auto"),
    .init(id: "plan", title: "Plan", subtitle: "Plan mode", cliHint: "--permission-mode plan"),
    .init(id: "dontAsk", title: "Don't Ask", subtitle: "Minimize prompts", cliHint: "--permission-mode dontAsk"),
    .init(id: "allow-bypass", title: "Allow Bypass", subtitle: "Optional bypass", cliHint: "--allow-dangerously-skip-permissions"),
    .init(id: "safe", title: "Safe", subtitle: "Safe mode", cliHint: "--safe-mode"),
  ]
  private var cfgURL: URL {
    FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".fuckcc/config")
  }
  private var workURL: URL {
    FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".fuckcc/last_workdir")
  }
  init() {
    fuckccPath = Shell.resolveFuckcc() ?? "(missing)"
    loadRegions(); loadAllPrefs(); loadWorkDir()
    Task { await refreshStatus() }
  }
  func loadRegions() {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    for p in [home+"/Desktop/fuckcc/regions.json", home+"/desktop/fuckcc/regions.json",
              Bundle.main.resourcePath.map{$0+"/regions.json"} ?? ""] where !p.isEmpty {
      if let data = try? Data(contentsOf: URL(fileURLWithPath: p)),
         let obj = try? JSONSerialization.jsonObject(with: data) as? [String:[String:Any]] {
        regions = obj.keys.sorted().compactMap { id in
          guard let v = obj[id] else { return nil }
          return RegionItem(id: id, name: (v["name"] as? String) ?? id, tz: (v["TZ"] as? String) ?? "")
        }
        if !regions.isEmpty { return }
      }
    }
  }
  func loadAllPrefs() {
    let p = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".fuckcc/current_region")
    if let s = try? String(contentsOf: p, encoding: .utf8) {
      let r = s.trimmingCharacters(in: .whitespacesAndNewlines)
      if !r.isEmpty { region = r }
    }
    guard let text = try? String(contentsOf: cfgURL, encoding: .utf8) else { return }
    for line in text.split(separator: "\n") {
      let l = String(line)
      if l.hasPrefix("LAUNCH_MODE=") { launchMode = String(l.dropFirst(12)) }
      if l.hasPrefix("PROMPT_TRANSLATE=") {
        let v = String(l.dropFirst(17)); translateOn = !(v == "0" || v == "false" || v == "off")
      }
      if l.hasPrefix("APP_LANG=") {
        let v = String(l.dropFirst(9))
        appLang = AppLang(rawValue: v) ?? .auto
      }
      if l.hasPrefix("HIDE_LEVEL=") {
        if let n = Int(String(l.dropFirst(11)).trimmingCharacters(in: .whitespaces)) {
          hideLevel = n
        }
      }
    }
  }
  func loadWorkDir() {
    if let s = try? String(contentsOf: workURL, encoding: .utf8) {
      let d = s.trimmingCharacters(in: .whitespacesAndNewlines)
      if !d.isEmpty, FileManager.default.fileExists(atPath: d) { workDir = d; return }
    }
    workDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").path
  }
  func saveWorkDir(_ path: String) {
    workDir = path
    try? path.write(to: workURL, atomically: true, encoding: .utf8)
  }
  func showBanner(_ s: String) {
    banner = s
    Task { try? await Task.sleep(nanoseconds: 2_300_000_000); if banner == s { banner = nil } }
  }
  var launchCliHint: String {
    launchModes.first(where: { $0.id == launchMode })?.cliHint ?? launchMode
  }
  func setRegion(_ id: String) {
    guard !busy else { return }; busy = true
    Task.detached {
      let r = Shell.runFuckcc(["use", id])
      await MainActor.run {
        self.busy = false; self.detailLog = r.1
        if r.0 == 0 { self.region = id; self.showBanner("✓ \(id)"); self.loadAllPrefs() }
        else { self.showBanner("region failed") }
      }
    }
  }
  func setLaunchMode(_ id: String) {
    guard !busy else { return }; busy = true
    Task.detached {
      let r = Shell.runFuckcc(["mode", id])
      await MainActor.run {
        self.busy = false; self.detailLog = r.1
        if r.0 == 0 { self.launchMode = id; self.showBanner("✓ \(id)"); self.loadAllPrefs() }
        else { self.showBanner("mode failed") }
      }
    }
  }
  func setTranslate(_ on: Bool) {
    guard !busy else { return }; busy = true
    let arg = on ? "on" : "off"
    Task.detached {
      let r = Shell.runFuckcc(["translate", arg])
      await MainActor.run {
        self.busy = false; self.detailLog = r.1
        if r.0 == 0 { self.translateOn = on; self.showBanner(on ? "translate ON" : "translate OFF") }
        else { self.showBanner("translate failed"); self.loadAllPrefs() }
      }
    }
  }
  func setAppLang(_ lang: AppLang) {
    guard !busy else { return }; busy = true
    Task.detached {
      let r = Shell.runFuckcc(["lang", lang.rawValue])
      await MainActor.run {
        self.busy = false; self.detailLog = r.1
        if r.0 == 0 { self.appLang = lang; self.showBanner(lang.label) }
        else { self.showBanner("lang failed") }
      }
    }
  }
  func setHideLevel(_ level: Int) {
    guard !busy else { return }; busy = true
    Task.detached {
      let r = Shell.runFuckcc(["hide", "\(level)"])
      await MainActor.run {
        self.busy = false; self.detailLog = r.1
        if r.0 == 0 { self.hideLevel = level; self.showBanner("hide \(level)"); self.loadAllPrefs() }
        else { self.showBanner("hide failed") }
      }
    }
  }
  func pickWorkDir() {
    if let path = Shell.pickFolder(start: workDir.isEmpty ? nil : workDir) {
      saveWorkDir(path); showBanner("folder OK"); detailLog = path
    }
  }
  func refreshStatus() async {
    let st = await Task.detached { Shell.runFuckcc(["status"]) }.value
    let mode = await Task.detached { Shell.runFuckcc(["mode"]) }.value
    let tr = await Task.detached { Shell.runFuckcc(["translate", "status"]) }.value
    detailLog = [st.1, mode.1, tr.1].joined(separator: "\n")
    var pOK = false
    let state = FileManager.default.homeDirectoryForCurrentUser.path + "/.fuckcc/proxy.state.json"
    if let data = try? Data(contentsOf: URL(fileURLWithPath: state)),
       let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      if let pid = j["pid"] as? Int { pOK = Shell.processAlive(pid) }
      else if let pid = j["pid"] as? String, let n = Int(pid) { pOK = Shell.processAlive(n) }
    }
    proxyOK = pOK
    translateOK = Shell.httpOK("http://127.0.0.1:19284/health")
    loadAllPrefs(); loadWorkDir()
    fuckccPath = Shell.resolveFuckcc() ?? "(missing)"
    statusText = L.ready
  }
  func startServices() {
    guard !busy else { return }; busy = true
    Task.detached {
      let a = Shell.runFuckcc(["proxy-start"])
      let b = Shell.runFuckcc(["translate-daemon-start"])
      await MainActor.run {
        self.busy = false; self.detailLog = a.1 + "\n" + b.1
        self.showBanner("services"); Task { await self.refreshStatus() }
      }
    }
  }
  func installAll() {
    guard !busy else { return }; busy = true
    Task.detached {
      let r = Shell.runFuckcc(["install"], timeout: 180)
      let s = Shell.runFuckcc(["translate-setup"], timeout: 600)
      let d = Shell.runFuckcc(["translate-daemon-start"])
      await MainActor.run {
        self.busy = false
        self.detailLog = [r.1, s.1, d.1].joined(separator: "\n")
        self.showBanner(r.0 == 0 ? "install OK" : "install issues")
        Task { await self.refreshStatus() }
      }
    }
  }
  func launchClaude(forcePick: Bool) {
    guard let bin = Shell.resolveFuckcc() else { showBanner("no fuckcc"); return }
    var dir = workDir
    if forcePick {
      guard let picked = Shell.pickFolder(start: dir.isEmpty ? nil : dir) else {
        showBanner("cancelled"); return
      }
      saveWorkDir(picked); dir = picked
    } else if dir.isEmpty || !FileManager.default.fileExists(atPath: dir) {
      guard let picked = Shell.pickFolder(start: nil) else { showBanner("need folder"); return }
      saveWorkDir(picked); dir = picked
    }
    let mode = launchMode
    let qDir = dir.replacingOccurrences(of: "'", with: "'\\''")
    let qBin = bin.replacingOccurrences(of: "'", with: "'\\''")
    let cmd = "cd '\(qDir)' && export FUCKCC_LAUNCH_MODE='\(mode)' && '\(qBin)' run"
    let script = "tell application \"Terminal\"\nactivate\ndo script \"\(cmd)\"\nend tell"
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    task.arguments = ["-e", script]
    do {
      try task.run()
      showBanner("Claude · \(mode)")
      detailLog = "dir: \(dir)\nmode: \(mode)\n\(launchCliHint)\n\n\(cmd)\n"
      Shell.log(cmd)
    } catch {
      showBanner("launch fail"); detailLog = error.localizedDescription
    }
  }
}
private enum UI {
  static let gridH: CGFloat = 76
  static let actionH: CGFloat = 44
  static let primaryH: CGFloat = 52
  static let r: CGFloat = 22
  static let pad: CGFloat = 18
}
struct ContentView: View {
  @StateObject private var model = FuckCCModel()
  private var L: L10n { model.L }
  var body: some View {
    ZStack {
      Color.white.ignoresSafeArea()
      VStack(spacing: 0) {
        header
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            statusStrip
            settingsCard
            workDirCard
            section(L.region)
            regionGrid
            section(L.mode)
            modeGrid
            actions
            logCard
            guideBtn
          }
          .padding(UI.pad)
          .padding(.bottom, 24)
        }
      }
      if model.busy {
        Color.black.opacity(0.05).ignoresSafeArea()
        ProgressView(model.statusText)
          .padding(24)
          .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 12))
      }
    }
    .overlay(alignment: .bottom) {
      if let b = model.banner {
        Text(b).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
          .padding(.horizontal, 18).padding(.vertical, 11)
          .background(Capsule().fill(Color.orange))
          .padding(.bottom, 16)
      }
    }
    .sheet(isPresented: $model.showHelp) {
      HelpSheet(lang: model.appLang).frame(width: 500, height: 620)
    }
    .preferredColorScheme(.light)
  }
  var header: some View {
    HStack(spacing: 12) {
      if let img = NSApp.applicationIconImage {
        Image(nsImage: img).resizable().frame(width: 40, height: 40)
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
      VStack(alignment: .leading, spacing: 2) {
        Text("fuckcc").font(.system(size: 20, weight: .bold, design: .rounded))
        Text(L.appSubtitle).font(.system(size: 11)).foregroundStyle(.secondary)
      }
      Spacer()
      Button { model.showHelp = true } label: {
        Label(L.help, systemImage: "questionmark.circle").frame(minWidth: 100, minHeight: UI.actionH)
      }.buttonStyle(SoftRound())
      Button { Task { await model.refreshStatus() } } label: {
        Image(systemName: "arrow.clockwise").frame(width: UI.actionH, height: UI.actionH)
      }.buttonStyle(SoftRound(circle: true))
    }
    .padding(.horizontal, UI.pad).padding(.top, 14).padding(.bottom, 6)
  }
  var statusStrip: some View {
    HStack(spacing: 8) {
      cell(L.statusRegion, model.region)
      cell(L.statusProxy, model.proxyOK ? L.running : L.stopped)
      cell(L.statusTranslate, model.translateOK ? L.ready : L.notReady)
      cell(L.statusMode, model.launchMode)
    }
  }
  func cell(_ t: String, _ v: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(t).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
      Text(v).font(.system(size: 12, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    .padding(.horizontal, 12)
    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(white: 0.97)))
  }
  var settingsCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text(L.translateOn).font(.system(size: 13, weight: .semibold))
          Text(L.translateHint).font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        Spacer()
        Toggle("", isOn: Binding(
          get: { model.translateOn },
          set: { model.setTranslate($0) }
        ))
        .labelsHidden()
        .toggleStyle(.switch)
        .tint(.orange)
      }
      Divider().opacity(0.3)
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("伪装深度").font(.system(size: 13, weight: .semibold))
          Text("1基础 · 2深藏 · 3最深").font(.system(size: 10)).foregroundStyle(.secondary)
        }
        Spacer()
        Picker("", selection: Binding(
          get: { model.hideLevel },
          set: { model.setHideLevel($0) }
        )) {
          Text("1").tag(1)
          Text("2").tag(2)
          Text("3 最深").tag(3)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 180)
      }
      Divider().opacity(0.3)
      HStack {
        Text(L.appLang).font(.system(size: 13, weight: .semibold))
        Spacer()
        Picker("", selection: Binding(
          get: { model.appLang },
          set: { model.setAppLang($0) }
        )) {
          ForEach(AppLang.allCases) { l in
            Text(l.label).tag(l)
          }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: 160)
      }
    }
    .padding(16)
    .background(RoundedRectangle(cornerRadius: UI.r, style: .continuous).fill(Color(white: 0.97)))
  }
  var workDirCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(L.workDir).font(.system(size: 13, weight: .semibold))
      Text(model.workDir.isEmpty ? L.noWorkDir : model.workDir)
        .font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary).lineLimit(2)
        .textSelection(.enabled)
      HStack(spacing: 10) {
        Button { model.pickWorkDir() } label: {
          Label(L.pickFolder, systemImage: "folder").frame(maxWidth: .infinity, minHeight: UI.actionH)
        }.buttonStyle(SoftRound())
        Button { model.launchClaude(forcePick: false) } label: {
          Label(L.launchHere, systemImage: "play.fill").frame(maxWidth: .infinity, minHeight: UI.actionH)
        }.buttonStyle(SoftRound()).disabled(model.workDir.isEmpty)
      }
    }
    .padding(16)
    .background(RoundedRectangle(cornerRadius: UI.r, style: .continuous).fill(Color(white: 0.97)))
  }
  func section(_ s: String) -> some View {
    Text(s).font(.system(size: 13, weight: .semibold))
  }
  var regionGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
      ForEach(model.regions) { r in
        let on = model.region == r.id
        Button { model.setRegion(r.id) } label: {
          HStack {
            VStack(alignment: .leading, spacing: 3) {
              Text(r.name).font(.system(size: 12, weight: .semibold)).lineLimit(1)
              Text(r.tz).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: on ? "checkmark.circle.fill" : "circle")
              .foregroundStyle(on ? Color.orange : Color.secondary.opacity(0.35))
          }
          .padding(.horizontal, 14)
          .frame(maxWidth: .infinity, minHeight: UI.gridH, maxHeight: UI.gridH, alignment: .leading)
        }
        .buttonStyle(SelectRound(selected: on)).disabled(model.busy)
      }
    }
  }
  var modeGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
      ForEach(model.launchModes) { m in
        let on = model.launchMode == m.id
        Button { model.setLaunchMode(m.id) } label: {
          VStack(alignment: .leading, spacing: 3) {
            HStack {
              Text(m.title).font(.system(size: 12, weight: .semibold))
              Spacer()
              Image(systemName: on ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(on ? Color.orange : Color.secondary.opacity(0.35))
            }
            Text(m.subtitle).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
            Text(m.cliHint).font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary).lineLimit(2)
          }
          .padding(.horizontal, 14).padding(.vertical, 8)
          .frame(maxWidth: .infinity, minHeight: UI.gridH + 6, maxHeight: UI.gridH + 6, alignment: .leading)
        }
        .buttonStyle(SelectRound(selected: on)).disabled(model.busy)
      }
    }
  }
  var actions: some View {
    VStack(spacing: 10) {
      Button { model.launchClaude(forcePick: true) } label: {
        VStack(spacing: 3) {
          Label(L.launchPick, systemImage: "terminal.fill").font(.system(size: 14, weight: .semibold))
          Text(model.launchMode == "bypass" ? "claude --dangerously-skip-permissions" : model.launchCliHint)
            .font(.system(size: 10, design: .monospaced)).opacity(0.92)
        }
        .frame(maxWidth: .infinity, minHeight: UI.primaryH)
      }
      .buttonStyle(PrimaryRound()).disabled(model.busy)
      HStack(spacing: 10) {
        Button { model.startServices() } label: {
          Label(L.services, systemImage: "bolt.fill").frame(maxWidth: .infinity, minHeight: UI.actionH)
        }.buttonStyle(SoftRound()).disabled(model.busy)
        Button { model.installAll() } label: {
          Label(L.install, systemImage: "hammer.fill").frame(maxWidth: .infinity, minHeight: UI.actionH)
        }.buttonStyle(SoftRound()).disabled(model.busy)
      }
    }
  }
  var logCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(L.log).font(.system(size: 13, weight: .semibold))
        Spacer()
        Text(model.statusText).font(.system(size: 11)).foregroundStyle(.secondary)
      }
      ScrollView {
        Text(model.detailLog.isEmpty ? "—" : model.detailLog)
          .font(.system(size: 10, design: .monospaced))
          .frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
      }.frame(minHeight: 90, maxHeight: 120)
    }
    .padding(16)
    .background(RoundedRectangle(cornerRadius: UI.r, style: .continuous).fill(Color(white: 0.97)))
  }
  var guideBtn: some View {
    Button { model.showHelp = true } label: {
      HStack {
        Image(systemName: "book.pages")
        Text(L.guideTeaser).font(.system(size: 12, weight: .medium))
        Spacer()
        Image(systemName: "chevron.right").foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, minHeight: UI.actionH).padding(.horizontal, 8)
    }.buttonStyle(SoftRound())
  }
}
struct SoftRound: ButtonStyle {
  var circle = false
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .semibold))
      .foregroundStyle(Color(red: 0.15, green: 0.14, blue: 0.13))
      .background {
        if circle { Circle().fill(Color(white: 0.96)) }
        else { Capsule(style: .continuous).fill(Color(white: 0.96)) }
      }
      .overlay {
        if circle { Circle().stroke(Color(white: 0.90), lineWidth: 1) }
        else { Capsule(style: .continuous).stroke(Color(white: 0.90), lineWidth: 1) }
      }
      .opacity(configuration.isPressed ? 0.85 : 1)
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
  }
}
struct SelectRound: ButtonStyle {
  var selected: Bool
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .fill(selected ? Color.orange.opacity(0.10) : Color(white: 0.97))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .stroke(selected ? Color.orange.opacity(0.55) : Color(white: 0.90), lineWidth: selected ? 1.5 : 1)
      )
      .opacity(configuration.isPressed ? 0.88 : 1)
  }
}
struct PrimaryRound: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(.white)
      .background(Capsule(style: .continuous).fill(Color.orange)
        .shadow(color: .orange.opacity(0.28), radius: 10, y: 4))
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
  }
}
struct HelpSheet: View {
  let lang: AppLang
  @Environment(\.dismiss) private var dismiss
  private var L: L10n { L10n(lang) }
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text(L.help).font(.system(size: 18, weight: .bold, design: .rounded))
        Spacer()
        Button("OK") { dismiss() }.buttonStyle(SoftRound())
      }.padding()
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(helpBlocks, id: \.0) { title, body in
            VStack(alignment: .leading, spacing: 8) {
              Text(title).font(.system(size: 14, weight: .semibold))
              Text(body).font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(white: 0.97)))
          }
        }
        .padding(.horizontal).padding(.bottom, 24)
      }
    }
    .background(Color.white)
  }
  var helpBlocks: [(String, String)] {
    let r = AppLang.resolve(lang)
    switch r {
    case .zh:
      return [
        ("1. 这是干什么的",
         "fuckcc 给 Claude Code 做进程级地区伪装，不改系统时区。提示词可翻译到所选地区语言，并要求用简体中文回答。安装一次后，终端直接敲 claude 即可，不必再开本 App。"),
        ("2. 推荐流程（只需一次完整安装）",
         "① 完整安装  ② 启动服务  ③ 选伪装地区  ④ 选启动模式（Bypass=--dangerously-skip-permissions）  ⑤ 打开/关闭提示词翻译  ⑥ 选择目录并启动 Claude。之后日常：cd 项目 && claude"),
        ("3. 提示词翻译",
         "开启后：任意语言输入 → 自动译成当前地区表面语言（美西=英语、日本=日语等），并用该语言写明「请用中文回答」。关闭后：不改写提示词。翻译默认本地免费（Argos/Apple）。"),
        ("4. 启动模式",
         "Bypass 全放行；Manual 每次问；Accept Edits 自动改文件；Auto/Plan/DontAsk 为官方 permission-mode；Safe 为 --safe-mode。"),
        ("5. 工作目录",
         "启动会弹出系统文件夹选择。也可先「选择文件夹」再「用当前目录启动」。路径记在 ~/.fuckcc/last_workdir。"),
        ("6. 命令行",
         "fuckcc install / use us-west / mode bypass / translate on|off / lang zh / run\nwhich claude 应指向 fuckcc shim。"),
        ("7. 日志",
         "界面日志区 + ~/.fuckcc/ui.log + fuckcc doctor / probe"),
      ]
    case .ja:
      return [
        ("1. 概要", "Claude Code のプロセス環境だけを偽装します。システム時区は変更しません。インストール後はターミナルで claude だけでOK。"),
        ("2. 初回", "フルインストール → サービス起動 → 地域 → 起動モード → 翻訳ON/OFF → フォルダ選択して起動。"),
        ("3. 翻訳", "任意言語→選択地域の言語へローカル無料翻訳。返答は簡体字中国語指定。"),
        ("4. モード", "Bypass は --dangerously-skip-permissions。他は permission-mode。"),
        ("5. 作業フォルダ", "起動前にフォルダ選択。"),
        ("6. CLI", "fuckcc install / use / mode / translate / run"),
      ]
    case .ko:
      return [
        ("1. 개요", "Claude Code 프로세스만 위장. 시스템 시간대 불변. 설치 후 터미널 claude 만 사용."),
        ("2. 처음", "전체 설치 → 서비스 → 지역 → 모드 → 번역 스위치 → 폴더 선택 실행."),
        ("3. 번역", "모든 언어 → 선택 지역 언어(로컬 무료). 답변은 중국어 간체 지시."),
        ("4. 모드", "Bypass = --dangerously-skip-permissions"),
        ("5. CLI", "fuckcc install / use / mode / translate / run"),
      ]
    case .de:
      return [
        ("1. Überblick", "Camouflage nur für den Claude-Code-Prozess. Nach Installation genügt claude im Terminal."),
        ("2. Ersteinrichtung", "Vollinstallation → Dienste → Region → Modus → Übersetzung → Ordner wählen & starten."),
        ("3. Übersetzung", "Beliebige Sprache → Regionssprache lokal/gratis. Antwort auf Chinesisch (vereinfacht) anweisen."),
        ("4. Modi", "Bypass = --dangerously-skip-permissions"),
        ("5. CLI", "fuckcc install / use / mode / translate / run"),
      ]
    default:
      return [
        ("1. What is this",
         "fuckcc camouflages the Claude Code process only (timezone/locale/proxy skin). It does NOT change your system timezone. After Full install, just run claude in Terminal — no need to open this app every time."),
        ("2. First-time setup",
         "1) Full install  2) Start services  3) Pick region  4) Pick launch mode (Bypass = --dangerously-skip-permissions)  5) Toggle prompt translation  6) Choose folder & launch. Daily: cd project && claude"),
        ("3. Prompt translation",
         "ON: any input language → selected region surface language (local free: Argos/Apple), with an instruction to reply in Simplified Chinese. OFF: prompts unchanged."),
        ("4. Launch modes",
         "Bypass full skip; Manual ask always; Accept Edits; Auto/Plan/DontAsk = official --permission-mode; Safe = --safe-mode."),
        ("5. Working folder",
         "Launch opens a system folder picker. Or set folder first, then Launch in current folder. Saved in ~/.fuckcc/last_workdir."),
        ("6. CLI equivalents",
         "fuckcc install\nfuckcc use us-west\nfuckcc mode bypass\nfuckcc translate on|off\nfuckcc lang en|zh|ja|ko|de\ncd /path && fuckcc run   # or just: claude"),
        ("7. Logs",
         "In-app log + ~/.fuckcc/ui.log + fuckcc doctor / probe"),
      ]
    }
  }
}
