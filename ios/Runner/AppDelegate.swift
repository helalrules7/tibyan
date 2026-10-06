import Flutter
import Photos
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Pack-download notifications (background_downloader).
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // «Save to Photos» for shared verse pictures, on whichever engine runs.
    PhotoSaverChannel.attach(engineBridge.applicationRegistrar.messenger())
    // CarPlay may have started the app first: the phone's view controller
    // then adopted the launch engine CarPlay set up (CarPlaySceneDelegate
    // .swift), whose plugins and car channel are already registered.
    if engineBridge.pluginRegistry.hasPlugin(CarPlayBridge.pluginKey) { return }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    CarPlayBridge.shared.attach(engineBridge.applicationRegistrar.messenger())
  }
}

/// Saves PNG files to the Photos library («Save to Photos» of the shared
/// verse pictures), in a «Tibyan» album when the reader allows full
/// access (NSPhotoLibraryUsageDescription); with add-only access
/// (NSPhotoLibraryAddUsageDescription) they go to the library itself.
enum PhotoSaverChannel {
  private static var channel: FlutterMethodChannel?
  private static let album = "Tibyan"

  static func attach(_ messenger: FlutterBinaryMessenger) {
    let c = FlutterMethodChannel(name: "app.tibyan/photos", binaryMessenger: messenger)
    c.setMethodCallHandler { call, result in
      guard call.method == "saveImages",
        let args = call.arguments as? [String: Any],
        let paths = args["paths"] as? [String]
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      save(paths, result)
    }
    channel = c
  }

  private static func save(_ paths: [String], _ result: @escaping FlutterResult) {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      if status == .authorized {
        saveInAlbum(paths, result)
        return
      }
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        guard status == .authorized || status == .limited else {
          DispatchQueue.main.async { result(false) }
          return
        }
        PHPhotoLibrary.shared().performChanges({
          for path in paths {
            PHAssetCreationRequest.forAsset().addResource(
              with: .photo, fileURL: URL(fileURLWithPath: path), options: nil)
          }
        }) { ok, _ in
          DispatchQueue.main.async { result(ok) }
        }
      }
    }
  }

  /// The pictures, added to the «Tibyan» album (made the first time).
  private static func saveInAlbum(_ paths: [String], _ result: @escaping FlutterResult) {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "title = %@", album)
    let existing = PHAssetCollection.fetchAssetCollections(
      with: .album, subtype: .any, options: options
    ).firstObject
    PHPhotoLibrary.shared().performChanges({
      let albumRequest =
        existing.flatMap { PHAssetCollectionChangeRequest(for: $0) }
        ?? PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: album)
      var added: [PHObjectPlaceholder] = []
      for path in paths {
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: .photo, fileURL: URL(fileURLWithPath: path), options: nil)
        if let placeholder = request.placeholderForCreatedAsset { added.append(placeholder) }
      }
      albumRequest.addAssets(added as NSArray)
    }) { ok, _ in
      DispatchQueue.main.async { result(ok) }
    }
  }
}
