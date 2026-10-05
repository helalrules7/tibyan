import Cocoa
import FlutterMacOS
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
    }
    super.applicationDidFinishLaunching(notification)
  }

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
