import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/contrast.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';

/// Regression test: a selected radio button was white on white in the
/// Calm light style because controls used the surah-header colour.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'selected radio and switch are visible in every style and mode',
    () async {
      final registry = await ThemeRegistry.load(rootBundle);
      final failures = <String>[];
      for (final style in registry.styles) {
        for (final mode in ThemeModeId.values) {
          final theme = buildTheme(
            style: style,
            mode: mode,
            uiFont: UiFont.plex,
          );
          final paper = style.modes[mode]!.paper;
          final selected = {WidgetState.selected};
          final radio = theme.radioTheme.fillColor!.resolve(selected)!;
          final track = theme.switchTheme.trackColor!.resolve(selected)!;
          final thumb = theme.switchTheme.thumbColor!.resolve(selected)!;
          void check(String what, double ratio, double min) {
            if (ratio < min) {
              failures.add(
                '${style.id}/${mode.name}: $what ${ratio.toStringAsFixed(2)}',
              );
            }
          }

          check('selected radio vs paper', contrastRatio(radio, paper), 3);
          check('switch track vs paper', contrastRatio(track, paper), 3);
          check('switch thumb vs track', contrastRatio(thumb, track), 3);
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
  );
}
