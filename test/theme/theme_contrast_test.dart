import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/theme/contrast.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';

/// Fails the build if any style/mode breaks a contrast rule.
/// Quran text >= 7:1, interface text >= 4.5:1, verse markers >= 3:1.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeRegistry registry;
  setUpAll(() async => registry = await ThemeRegistry.load(rootBundle));

  test('every style defines all three modes', () {
    expect(registry.styles, isNotEmpty);
    for (final style in registry.styles) {
      expect(
        style.modes.keys.toSet(),
        ThemeModeId.values.toSet(),
        reason: style.id,
      );
    }
  });

  test('default style exists', () {
    expect(registry.styles.map((s) => s.id), contains(registry.defaultStyleId));
  });

  final rules =
      <
        (String, Color Function(ModeTokens), Color Function(ModeTokens), double)
      >[
        ('Quran text on paper', (t) => t.ink, (t) => t.paper, 7),
        ('Text on background', (t) => t.ink, (t) => t.bg, 7),
        ('Muted text on paper', (t) => t.muted, (t) => t.paper, 4.5),
        ('Muted text on background', (t) => t.muted, (t) => t.bg, 4.5),
        ('Gold text on paper', (t) => t.goldText, (t) => t.paper, 4.5),
        ('Surah header', (t) => t.headFg, (t) => t.headBg, 4.5),
        ('Player bar', (t) => t.playerFg, (t) => t.player, 4.5),
        ('Accent button', (t) => t.accentFg, (t) => t.accent, 4.5),
        ('Verse marker on paper', (t) => t.marker, (t) => t.paper, 3),
        ('Selected control on paper', (t) => t.control, (t) => t.paper, 3),
        ('Selected control on background', (t) => t.control, (t) => t.bg, 3),
        ('Text on selected control', (t) => t.onControl, (t) => t.control, 4.5),
      ];

  test('contrast rules hold for every style and mode', () {
    final failures = <String>[];
    for (final style in registry.styles) {
      for (final entry in style.modes.entries) {
        for (final (name, fg, bg, min) in rules) {
          final ratio = contrastRatio(fg(entry.value), bg(entry.value));
          if (ratio < min) {
            failures.add(
              '${style.id}/${entry.key.name}: $name = '
              '${ratio.toStringAsFixed(2)} (min $min)',
            );
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('hex parser handles alpha', () {
    expect(parseHexColor('#B8923E38').a, closeTo(0x38 / 255, 0.01));
    expect(() => parseHexColor('#123'), throwsFormatException);
  });
}
