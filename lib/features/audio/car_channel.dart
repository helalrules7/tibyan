import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'car_browser.dart';

/// CarPlay's way into [CarBrowser]: the iOS CarPlay scene
/// (ios/Runner/CarPlaySceneDelegate.swift) asks over `app.tibyan/car`:
///
/// - `children(id)` → `[{id, title, subtitle?, playable}]` (`root` for the top)
/// - `play(id)` → starts the recitation, returns null
///
/// and is told `ready` once this side answers, so a car that connected
/// before the app finished starting can fill its lists.
class CarChannel {
  CarChannel(this.browser, {MethodChannel? channel})
    : channel = channel ?? const MethodChannel(name);

  static const name = 'app.tibyan/car';

  final MediaBrowserDelegate browser;
  final MethodChannel channel;

  Future<void> attach() async {
    channel.setMethodCallHandler(handle);
    try {
      await channel.invokeMethod<void>('ready');
    } on MissingPluginException {
      // No CarPlay scene code on this side (tests, or an older build).
    } on PlatformException {
      // Same: nothing to tell.
    }
  }

  @visibleForTesting
  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'children':
        final id = call.arguments is String
            ? call.arguments as String
            : CarBrowser.root;
        return [
          for (final item in await browser.children(id))
            {
              'id': item.id,
              'title': item.title,
              if (item.artist != null) 'subtitle': item.artist,
              'playable': item.playable ?? false,
            },
        ];
      case 'play':
        final id = call.arguments;
        if (id is String) await browser.play(id);
        return null;
    }
    throw MissingPluginException('${call.method} is not a car call');
  }
}
