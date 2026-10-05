import Flutter
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
    // CarPlay may have started the app first: the phone's view controller
    // then adopted the launch engine CarPlay set up (CarPlaySceneDelegate
    // .swift), whose plugins and car channel are already registered.
    if engineBridge.pluginRegistry.hasPlugin(CarPlayBridge.pluginKey) { return }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    CarPlayBridge.shared.attach(engineBridge.applicationRegistrar.messenger())
  }
}
