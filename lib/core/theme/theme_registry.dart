import 'dart:convert';

import 'package:flutter/services.dart';

import 'theme_tokens.dart';

/// All styles found in `assets/themes/index.json`.
class ThemeRegistry {
  const ThemeRegistry({required this.defaultStyleId, required this.styles});

  final String defaultStyleId;
  final List<TibyanStyle> styles;

  TibyanStyle byId(String id) => styles.firstWhere(
    (s) => s.id == id,
    orElse: () => styles.firstWhere((s) => s.id == defaultStyleId),
  );

  static Future<ThemeRegistry> load(AssetBundle bundle) async {
    final index = jsonDecode(
      await bundle.loadString('assets/themes/index.json'),
    ) as Map<String, dynamic>;
    final ids = List<String>.from(index['styles'] as List);
    final styles = <TibyanStyle>[
      for (final id in ids)
        TibyanStyle.fromJson(
          jsonDecode(await bundle.loadString('assets/themes/$id.json'))
              as Map<String, dynamic>,
        ),
    ];
    return ThemeRegistry(
      defaultStyleId: index['default'] as String,
      styles: styles,
    );
  }
}
