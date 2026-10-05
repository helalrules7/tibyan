import Flutter
import UIKit

#if canImport(CarPlay)
import CarPlay
#endif

/// The Dart side of the car over `app.tibyan/car`
/// (lib/features/audio/car_channel.dart, which answers from CarBrowser):
///
/// - `children(id)` → `[{id, title, subtitle?, playable}]`
/// - `play(id)`
/// - Dart calls `ready` once it answers.
///
/// The channel lives on the app's one Flutter engine: the phone UI's
/// implicit engine (AppDelegate.didInitializeImplicitFlutterEngine), or,
/// when CarPlay starts the app before the phone UI exists, the engine
/// FlutterAppDelegate keeps for launch ("launch engine"), which the phone's
/// FlutterViewController adopts when it appears. See docs/CARPLAY.md.
final class CarPlayBridge {
  static let shared = CarPlayBridge()
  static let channelName = "app.tibyan/car"
  /// The registrar key used on the launch engine; its presence on an engine
  /// tells AppDelegate that CarPlay already set that engine up.
  static let pluginKey = "TibyanCarPlay"

  struct Entry {
    let id: String
    let title: String
    let subtitle: String?
    let playable: Bool
  }

  private var channel: FlutterMethodChannel?
  private(set) var isReady = false
  /// Called (on the main thread) when Dart says it answers.
  var onReady: (() -> Void)?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "ready" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.isReady = true
      self?.onReady?()
      result(nil)
    }
    self.channel = channel
    isReady = false
  }

  /// Makes sure a Flutter engine runs the app's Dart code, so the car has
  /// someone to ask even when the phone UI was never opened.
  func ensureEngine() {
    guard channel == nil,
      let app = UIApplication.shared.delegate as? FlutterAppDelegate
    else { return }
    // FlutterAppDelegate hands out registrars of its launch engine, started
    // headless on first use; the storyboard's FlutterViewController takes
    // that engine over later instead of making a second one.
    guard let registrar = app.registrar(forPlugin: Self.pluginKey) else { return }
    GeneratedPluginRegistrant.register(with: app)
    attach(registrar.messenger())
  }

  func children(of id: String, _ done: @escaping ([Entry]) -> Void) {
    guard let channel = channel else {
      done([])
      return
    }
    channel.invokeMethod("children", arguments: id) { result in
      let rows = result as? [[String: Any]] ?? []
      done(
        rows.compactMap { (row: [String: Any]) -> Entry? in
          guard let id = row["id"] as? String, let title = row["title"] as? String else {
            return nil
          }
          return Entry(
            id: id,
            title: title,
            subtitle: row["subtitle"] as? String,
            playable: row["playable"] as? Bool ?? false
          )
        })
    }
  }

  func play(_ id: String, _ done: @escaping () -> Void) {
    guard let channel = channel else {
      done()
      return
    }
    channel.invokeMethod("play", arguments: id) { _ in done() }
  }
}

#if canImport(CarPlay)
/// CarPlay (audio app): «تابع من موضع القراءة» and «القراء» → a reciter →
/// the surahs; choosing one plays it and shows Now Playing.
///
/// Declared in Info.plist (CPTemplateApplicationSceneSessionRoleApplication).
/// CarPlay only creates this scene once the app is signed with the
/// com.apple.developer.carplay-audio entitlement (tools/apple/carplay.rb).
@available(iOS 14.0, *)
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private var interfaceController: CPInterfaceController?
  private var root: CPListTemplate?

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    self.interfaceController = interfaceController
    let bridge = CarPlayBridge.shared
    bridge.ensureEngine()

    let root = CPListTemplate(title: "تبيان", sections: [])
    root.emptyViewTitleVariants = ["تبيان"]
    root.emptyViewSubtitleVariants = ["جارٍ التحميل…"]
    self.root = root
    interfaceController.setRootTemplate(root, animated: false, completion: nil)

    bridge.onReady = { [weak self] in self?.reloadRoot() }
    reloadRoot()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    CarPlayBridge.shared.onReady = nil
    self.interfaceController = nil
    root = nil
  }

  private func reloadRoot() {
    guard let root = root else { return }
    CarPlayBridge.shared.children(of: "root") { [weak self] entries in
      self?.show(entries, in: root)
    }
  }

  private func show(_ entries: [CarPlayBridge.Entry], in template: CPListTemplate) {
    let shown = entries.prefix(CPListTemplate.maximumItemCount).map { listItem($0) }
    template.updateSections([CPListSection(items: Array(shown))])
  }

  private func listItem(_ entry: CarPlayBridge.Entry) -> CPListItem {
    let item = CPListItem(text: entry.title, detailText: entry.subtitle)
    if !entry.playable {
      item.accessoryType = .disclosureIndicator
    }
    item.handler = { [weak self] _, completion in
      guard let self = self else {
        completion()
        return
      }
      if entry.playable {
        CarPlayBridge.shared.play(entry.id) {
          completion()
          self.showNowPlaying()
        }
      } else {
        CarPlayBridge.shared.children(of: entry.id) { entries in
          let list = CPListTemplate(title: entry.title, sections: [])
          self.show(entries, in: list)
          self.interfaceController?.pushTemplate(list, animated: true, completion: nil)
          completion()
        }
      }
    }
    return item
  }

  private func showNowPlaying() {
    guard let controller = interfaceController else { return }
    let nowPlaying = CPNowPlayingTemplate.shared
    if controller.topTemplate === nowPlaying { return }
    if controller.templates.contains(where: { $0 === nowPlaying }) {
      controller.pop(to: nowPlaying, animated: true, completion: nil)
    } else {
      controller.pushTemplate(nowPlaying, animated: true, completion: nil)
    }
  }
}
#endif
