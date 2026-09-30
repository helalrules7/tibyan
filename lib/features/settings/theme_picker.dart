import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../onboarding/page_preview.dart';

/// A card per style (Zakhrafa and the heritage themes): a small page in
/// its frame, in the current mode, and its name. Tapping one picks it.
class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key, this.columns = 3});

  final int columns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(themeRegistryProvider);
    final selectedId = ref.watch(settingsProvider.select((s) => s.styleId));
    final controller = ref.read(settingsProvider.notifier);
    final tokens = context.tokens;
    final t = tokens.colors;
    final lang = Localizations.localeOf(context).languageCode;
    const gap = 10.0;
    return LayoutBuilder(
      builder: (context, box) {
        final cardW = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final style in registry.styles)
              Semantics(
                button: true,
                selected: style.id == selectedId,
                label: style.localizedName(lang),
                hint: style.localizedDescription(lang),
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => controller.setStyle(style.id),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: cardW,
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: style.id == selectedId ? t.control : t.border,
                        width: style.id == selectedId ? 2.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        RealPagePreview(
                          style: style,
                          mode: tokens.mode,
                          width: cardW - 16,
                          semanticLabel: style.localizedName(lang),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          style.localizedName(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
