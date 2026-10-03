#!/bin/sh
# Makes the theme picker's preview images: every style in every mode, drawn
# live by the app's own preview code (test/tools/render_theme_previews_test.dart),
# then saved as small WebP in assets/themes/preview_<style>_<mode>.webp.
# Run from the repository root after changing a theme.
set -e
RENDER_THEME_PREVIEWS=1 flutter test test/tools/render_theme_previews_test.dart
for f in build/theme_previews/*.png; do
  name=$(basename "$f" .png)
  magick "$f" -quality 82 -define webp:method=6 "assets/themes/preview_$name.webp"
done
ls -la assets/themes/preview_*.webp | awk '{s += $5} END {print NR " previews, " s " bytes"}'
