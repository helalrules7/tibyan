# just_audio_background (vendored)

A copy of [just_audio_background](https://pub.dev/packages/just_audio_background) 0.0.1-beta.17 (MIT, `LICENSE`), used through `dependency_overrides` in the app's `pubspec.yaml`.

Tibyan's only change: media browsing for Android Auto. The package's audio handler is private, so an app cannot answer `getChildren` / `playFromMediaId`; this copy adds `MediaBrowserDelegate` and `JustAudioBackground.browser`, and both the handler used before a player exists and the player's handler answer through it (`_Browsing`). Everything else is unchanged.

To update: copy the new release over this folder, then re-apply the additions marked by `MediaBrowserDelegate`, `_BrowsingAudioHandler` and `_Browsing`.
