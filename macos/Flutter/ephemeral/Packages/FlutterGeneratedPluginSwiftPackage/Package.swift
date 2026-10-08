// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "app_links", path: "../.packages/app_links-7.2.1"),
        .package(name: "audio_service", path: "../.packages/audio_service-0.18.19"),
        .package(name: "audio_session", path: "../.packages/audio_session-0.2.4"),
        .package(name: "connectivity_plus", path: "../.packages/connectivity_plus-7.3.1"),
        .package(name: "file_selector_macos", path: "../.packages/file_selector_macos-0.9.5+1"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.3.1"),
        .package(name: "flutter_timezone", path: "../.packages/flutter_timezone-5.1.1"),
        .package(name: "just_audio", path: "../.packages/just_audio-0.10.6"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-10.2.2"),
        .package(name: "record_macos", path: "../.packages/record_macos-2.1.1"),
        .package(name: "sentry_flutter", path: "../.packages/sentry_flutter-9.30.1"),
        .package(name: "share_plus", path: "../.packages/share_plus-13.3.1"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.7"),
        .package(name: "sherpa_onnx_macos", path: "../.packages/sherpa_onnx_macos-1.13.8"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.4"),
        .package(name: "wakelock_plus", path: "../.packages/wakelock_plus-1.8.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "app-links", package: "app_links"),
                .product(name: "audio-service", package: "audio_service"),
                .product(name: "audio-session", package: "audio_session"),
                .product(name: "connectivity-plus", package: "connectivity_plus"),
                .product(name: "file-selector-macos", package: "file_selector_macos"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "flutter-timezone", package: "flutter_timezone"),
                .product(name: "just-audio", package: "just_audio"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "record-macos", package: "record_macos"),
                .product(name: "sentry-flutter", package: "sentry_flutter"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sherpa-onnx-macos", package: "sherpa_onnx_macos"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "wakelock-plus", package: "wakelock_plus"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
