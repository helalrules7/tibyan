import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/go_to_page.dart';
import 'package:tibyan/l10n/app_localizations.dart';

void main() {
  testWidgets('go to page accepts 1 to 604 in either digit set', (
    tester,
  ) async {
    final registry = await ThemeRegistry.load(rootBundle);
    int? result = -1;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId('zakhrafa'),
            mode: ThemeModeId.light,
            uiFont: UiFont.plex,
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showGoToPage(context, current: 50),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '٧٠٠');
    await tester.pump();
    final go = find.widgetWithText(FilledButton, 'انتقال');
    expect(tester.widget<FilledButton>(go).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '٦٠٤');
    await tester.pump();
    await tester.tap(go);
    await tester.pumpAndSettle();
    expect(result, 604);
  });
}
