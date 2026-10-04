#!/bin/sh
# App Store screenshots: the app on a 6.9-inch iPhone simulator of its own
# ("Tibyan Store 6.9", created if missing), opened straight on each screen
# below (TIBYAN_START, see lib/features/splash/splash_screen.dart), in the
# Tibyan theme's light mode, in Arabic. Writes build/store_screenshots/.
# Run from the repository root.
set -e
NAME="Tibyan Store 6.9"
TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max"
UDID=$(xcrun simctl list devices | grep "$NAME (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
if [ -z "$UDID" ]; then UDID=$(xcrun simctl create "$NAME" "$TYPE"); fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
BUNDLE=app.tibyan.tibyan
OUT=build/store_screenshots
mkdir -p "$OUT"
n=0
for route in /mushaf / /mushaf/index /settings/appearance /settings; do
  n=$((n + 1))
  flutter build ios --simulator --debug --dart-define=TIBYAN_START="$route" >/dev/null
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl install "$UDID" build/ios/iphonesimulator/Runner.app
  # Past onboarding, Arabic, the Tibyan theme in light mode, tajweed on:
  # written into the app's preferences file (simctl spawn defaults hangs).
  PREFS="$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)/Library/Preferences"
  PLIST="$PREFS/$BUNDLE.plist"
  mkdir -p "$PREFS"
  # The keys hold dots, which plutil reads as a path: plistlib instead.
  python3 - "$PLIST" <<'PY'
import os, plistlib, sys
path = sys.argv[1]
prefs = plistlib.load(open(path, 'rb')) if os.path.exists(path) else {}
prefs.update({
    'flutter.settings.onboardingDone': True,
    'flutter.settings.language': 'ar',
    'flutter.settings.style': 'zakhrafa',
    'flutter.settings.mode': 'light',
    'flutter.settings.tajweedColors': True,
})
plistlib.dump(prefs, open(path, 'wb'))
PY
  xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
  # A fresh install first copies the content database: give it time.
  sleep 40
  xcrun simctl io "$UDID" screenshot "$OUT/$n$(echo "$route" | tr '/' '_').png" >/dev/null
done
ls -la "$OUT"
