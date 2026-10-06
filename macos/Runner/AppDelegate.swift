import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers
import WidgetKit

/// The macOS side of the home widgets: `home_widget` has no macOS support,
/// so the app writes the widgets' keys into the App Group itself (channel
/// `app.tibyan/widget`) and receives their `tibyan://` links.
@main
class AppDelegate: FlutterAppDelegate {
  private var channel: FlutterMethodChannel?

  /// A link that arrived before Dart asked for it (a widget tap that
  /// launched the app).
  private var initialLink: String?
  private var dartAsked = false

  private var groupId: String {
    (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String)
      ?? "group.app.tibyan.tibyan"
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let controller = NSApplication.shared.windows
      .compactMap({ $0.contentViewController as? FlutterViewController }).first
    {
      let ch = FlutterMethodChannel(
        name: "app.tibyan/widget", binaryMessenger: controller.engine.binaryMessenger)
      ch.setMethodCallHandler { [weak self] call, result in
        self?.handle(call, result: result)
      }
      channel = ch
      let photos = FlutterMethodChannel(
        name: "app.tibyan/photos", binaryMessenger: controller.engine.binaryMessenger)
      photos.setMethodCallHandler { call, result in
        guard call.method == "saveImages",
          let args = call.arguments as? [String: Any],
          let paths = args["paths"] as? [String]
        else {
          result(FlutterMethodNotImplemented)
          return
        }
        PictureSaver.save(paths, result)
      }
      photosChannel = photos
    }
    super.applicationDidFinishLaunching(notification)
  }

  private var photosChannel: FlutterMethodChannel?

  override func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first(where: { $0.scheme == "tibyan" }) else { return }
    if dartAsked {
      channel?.invokeMethod("link", arguments: url.absoluteString)
    } else {
      initialLink = url.absoluteString
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let defaults = UserDefaults(suiteName: groupId)
    switch call.method {
    case "save":
      if let entries = call.arguments as? [String: String] {
        for (key, value) in entries { defaults?.set(value, forKey: key) }
        WidgetCenter.shared.reloadAllTimelines()
      }
      result(nil)
    case "initialLink":
      dartAsked = true
      let link = initialLink
      initialLink = nil
      result(link)
    case "takePending":
      let pending = defaults?.string(forKey: "pending_actions")
      defaults?.set("", forKey: "pending_actions")
      result(pending)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

/// «Save» for the shared verse pictures: the reader chooses where, in the
/// system's save panel (one picture) or a folder (several). The sandbox
/// lets the app write there (com.apple.security.files.user-selected.read-write).
/// Answers the folder saved to, or nil when the reader cancelled.
enum PictureSaver {
  /// The reader's own Pictures folder (in the sandbox, HOME is the app's
  /// container).
  private static var pictures: URL? {
    guard let home = getpwuid(getuid())?.pointee.pw_dir else { return nil }
    return URL(fileURLWithPath: String(cString: home)).appendingPathComponent("Pictures")
  }

  static func save(_ paths: [String], _ result: @escaping FlutterResult) {
    let files = paths.map { URL(fileURLWithPath: $0) }
    guard !files.isEmpty else {
      result(nil)
      return
    }
    if files.count == 1 {
      let panel = NSSavePanel()
      panel.allowedContentTypes = [.png]
      panel.nameFieldStringValue = files[0].lastPathComponent
      panel.directoryURL = pictures
      panel.canCreateDirectories = true
      panel.begin { response in
        guard response == .OK, let target = panel.url else {
          result(nil)
          return
        }
        do {
          try? FileManager.default.removeItem(at: target)
          try FileManager.default.copyItem(at: files[0], to: target)
          result(target.deletingLastPathComponent().path)
        } catch {
          result(FlutterError(code: "save", message: error.localizedDescription, details: nil))
        }
      }
      return
    }
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.canCreateDirectories = true
    panel.allowsMultipleSelection = false
    panel.directoryURL = pictures
    panel.prompt = Locale.preferredLanguages.first?.hasPrefix("ar") == true ? "احفظ هنا" : "Save Here"
    panel.begin { response in
      guard response == .OK, let folder = panel.url else {
        result(nil)
        return
      }
      do {
        for file in files {
          let target = folder.appendingPathComponent(file.lastPathComponent)
          try? FileManager.default.removeItem(at: target)
          try FileManager.default.copyItem(at: file, to: target)
        }
        result(folder.path)
      } catch {
        result(FlutterError(code: "save", message: error.localizedDescription, details: nil))
      }
    }
  }
}
