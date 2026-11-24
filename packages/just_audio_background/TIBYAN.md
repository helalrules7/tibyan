# just_audio_background (vendored)

A copy of [just_audio_background](https://pub.dev/packages/just_audio_background) 0.0.1-beta.17 (MIT, `LICENSE`), used through `dependency_overrides` in the app's `pubspec.yaml`.

Tibyan's only change: media browsing for Android Auto. The package's audio handler is private, so an app cannot answer `getChildren` / `playFromMediaId`; this copy adds `MediaBrowserDelegate` and `JustAudioBackground.browser`, and both the handler used before a player exists and the player's handler answer through it (`_Browsing`). Everything else is unchanged.

To update: copy the new release over this folder, then re-apply the additions marked by `MediaBrowserDelegate`, `_BrowsingAudioHandler` and `_Browsing`.

Android Auto cold start (fix/android-auto): the car can bind the service before the app sets `JustAudioBackground.browser`. `getChildren` / `playFromMediaId` wait for it (`browserWait`, 20 s), `subscribeToChildren` returns a stream that fires when it is set, and setting it calls `notifyChildrenChanged(root)` so a car that got an empty root from the native side (before `AudioService.init`) reloads. A failed `playFromMediaId` puts the playback state in `error` with `MediaBrowserDelegate.playbackError`.
