import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/onboarding/page_preview.dart';

/// The theme picker shows images made ahead of time
/// (tools/render_theme_previews.sh): every style needs one in every mode,
/// or its card falls back to drawing the whole preview live.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every style has a preview image in every mode', () async {
    final registry = await ThemeRegistry.load(rootBundle);
    final missing = [
      for (final style in registry.styles)
        for (final mode in ThemeModeId.values)
          if (!File(RealPagePreview.assetFor(style.id, mode)).existsSync())
            '${style.id}/${mode.name}',
    ];
    expect(missing, isEmpty);
  });
}
