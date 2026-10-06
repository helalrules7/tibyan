import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/settings/app_settings.dart';
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

  testWidgets('the Shamarly edition has 522 pages', (tester) async {
    // The bundle caches loads made under the previous test's clock.
    rootBundle.clear();
    final registry = await ThemeRegistry.load(rootBundle);
    int? result = -1;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId('zakhrafa'),
            mode: ThemeModeId.light,
            uiFont: UiFont.plex,
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showGoToPage(
                context,
                current: 50,
                max: MushafEdition.shamarly.pageCount,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Page number, 1 to 522'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '523');
    await tester.pump();
    final go = find.widgetWithText(FilledButton, 'Go');
    expect(tester.widget<FilledButton>(go).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '522');
    await tester.pump();
    await tester.tap(go);
    await tester.pumpAndSettle();
    expect(result, 522);
  });

  testWidgets('Arabic interface: Arabic-Indic digits shown, both typed', (
    tester,
  ) async {
    rootBundle.clear();
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
                  result = await showGoToPage(context, current: 14),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    // The page number keyboard, digits only.
    expect(field.keyboardType, TextInputType.number);
    // The current page in the interface's digits.
    expect(field.controller!.text, '١٤');

    // Western digits typed are written as the interface writes them.
    await tester.enterText(find.byType(TextField), '255');
    await tester.pump();
    expect(field.controller!.text, '٢٥٥');
    // Letters and signs are refused; a fourth digit too.
    await tester.enterText(find.byType(TextField), '2a5-5١');
    await tester.pump();
    expect(field.controller!.text, '٢٥٥');

    // Arabic-Indic digits as typed.
    await tester.enterText(find.byType(TextField), '٣٠٠');
    await tester.pump();
    expect(field.controller!.text, '٣٠٠');
    await tester.tap(find.widgetWithText(FilledButton, 'انتقال'));
    await tester.pumpAndSettle();
    expect(result, 300);
  });

  test('digits of either set read as numbers', () {
    expect(latinDigits('١٢٣'), '123');
    expect(latinDigits('۴۵'), '45');
    expect(latinDigits('7٨'), '78');
    final ar = AppDigitsFormatter(arabic: true);
    final en = AppDigitsFormatter(arabic: false);
    const typed = TextEditingValue(
      text: '6٠4',
      selection: TextSelection.collapsed(offset: 3),
    );
    expect(ar.formatEditUpdate(TextEditingValue.empty, typed).text, '٦٠٤');
    expect(en.formatEditUpdate(TextEditingValue.empty, typed).text, '604');
    expect(
      ar.formatEditUpdate(TextEditingValue.empty, typed).selection,
      typed.selection,
    );
  });
}
