import AppKit
import Foundation
import Translation
@available(macOS 26.4, *)
@main
struct AppleTranslateCLI {
  static func main() async {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    var from = "zh-Hans"
    var to = "en"
    var strategyName = "lowLatency"
    var statusOnly = false
    var installOnly = false
    let args = Array(CommandLine.arguments.dropFirst())
    var textParts: [String] = []
    var i = 0
    while i < args.count {
      let a = args[i]
      switch a {
      case "--from", "-f":
        i += 1; if i < args.count { from = args[i] }
      case "--to", "-t":
        i += 1; if i < args.count { to = args[i] }
      case "--strategy", "-s":
        i += 1; if i < args.count { strategyName = args[i] }
      case "--status":
        statusOnly = true
      case "--install", "--prepare":
        installOnly = true
      case "-h", "--help":
        print(
          """
          apple_translate — macOS on-device Translation
            --from zh-Hans --to en
            --strategy lowLatency|highFidelity
            --status
            --install / --prepare   download language pack if needed
            text | stdin
          """
        )
        return
      default:
        textParts.append(a)
      }
      i += 1
    }
    var text = textParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty && !statusOnly && !installOnly {
      let data = FileHandle.standardInput.readDataToEndOfFile()
      if let stdin = String(data: data, encoding: .utf8) {
        text = stdin.trimmingCharacters(in: .whitespacesAndNewlines)
      }
    }
    let sourceLang = Locale.Language(identifier: from)
    let targetLang = Locale.Language(identifier: to)
    let strategy: TranslationSession.Strategy =
      strategyName.lowercased().contains("high") ? .highFidelity : .lowLatency
    let availability = LanguageAvailability(preferredStrategy: strategy)
    let st = await availability.status(from: sourceLang, to: targetLang)
    if statusOnly {
      switch st {
      case .installed: print("installed")
      case .supported: print("supported")
      case .unsupported: print("unsupported")
      @unknown default: print("unknown")
      }
      return
    }
    if st == .unsupported {
      fputs("error: language pair unsupported: \(from) -> \(to)\n", stderr)
      exit(3)
    }
    do {
      let session = TranslationSession(
        installedSource: sourceLang,
        target: targetLang,
        preferredStrategy: strategy
      )
      try await session.prepareTranslation()
      if installOnly {
        let st2 = await availability.status(from: sourceLang, to: targetLang)
        print(st2 == .installed ? "installed" : "prepared")
        return
      }
      if text.isEmpty {
        fputs("error: empty input\n", stderr)
        exit(2)
      }
      let response = try await session.translate(text)
      print(response.targetText)
    } catch {
      fputs("error: \(error)\n", stderr)
      fputs(
        "hint: open System Settings → General → Language & Region → Translation Languages\n"
          + "      or open Translate app and download \(from) / \(to)\n"
          + "      then re-run: apple_translate --install --from \(from) --to \(to)\n",
        stderr
      )
      exit(1)
    }
  }
}
