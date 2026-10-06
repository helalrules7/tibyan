import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tibyan/core/settings/app_settings.dart';
import 'package:tibyan/core/theme/app_theme.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/core/theme/theme_tokens.dart';
import 'package:tibyan/features/hifz/domain/strength.dart';
import 'package:tibyan/features/hifz/presentation/strength_style.dart';
import 'package:tibyan/features/mushaf/presentation/pages_map.dart';
import 'package:tibyan/l10n/app_localizations.dart';

/// The index's pages map: each page by its state in the khatma, its
/// memorization strength and its marks, grouped by juz.
void main() {
  group('pages of an edition', () {
    // Three verses: the second runs over a Shamarly page break.
    const cells = <VerseCell>[
      ('1:1', 1, 1, 1, 2, 2),
      ('2:1', 2, 2, 2, 2, 3),
      ('2:2', 2, 3, 2, 3, 3),
    ];

    test('a verse is on its page in each Hafs edition', () {
      expect(verseCellPages(cells[1], MushafEdition.madina1441), [2]);
      expect(verseCellPages(cells[1], MushafEdition.madina1405), [2]);
      expect(verseCellPages(cells[1], MushafEdition.shamarly), [2, 3]);
    });

    test('the khatma\'s pages, in the edition read', () {
      // The same edition: as read.
      expect(
        readPagesIn(
          {1, 2},
          from: MushafEdition.madina1441,
          to: MushafEdition.madina1441,
          cells: cells,
        ),
        {1, 2},
      );
      // Another: a page counts once all its verses are read.
      expect(
        readPagesIn(
          {1, 2},
          from: MushafEdition.madina1441,
          to: MushafEdition.madina1405,
          cells: cells,
        ),
        {1},
      );
      expect(
        readPagesIn(
          {1, 2, 3},
          from: MushafEdition.madina1441,
          to: MushafEdition.shamarly,
          cells: cells,
        ),
        {2, 3},
      );
      // A riwaya's pages are its own.
      expect(
        readPagesIn(
          {1, 2},
          from: MushafEdition.madina1441,
          to: MushafEdition.values.firstWhere((e) => e.isRiwaya),
          cells: cells,
        ),
        isEmpty,
      );
    });

    test('pages grouped by juz, the cover with the first', () {
      const data = PagesMapData(
        pageCount: 30,
        juzStarts: [2, 12, 22],
        pages: {},
        khatma: false,
      );
      expect(data.groups(), [(1, 1, 11), (2, 12, 21), (3, 22, 30)]);
    });
  });

  testWidgets('read, memorized, marked and current pages', (tester) async {
    final registry = await ThemeRegistry.load(rootBundle);
    const data = PagesMapData(
      pageCount: 44,
      juzStarts: [1, 22],
      khatma: true,
      pages: {
        3: PageMark(read: true),
        4: PageMark(strength: Strength.strong),
        5: PageMark(read: true, strength: Strength.weak),
        6: PageMark(marks: [Color(0xFF2E7D32)]),
      },
    );
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pagesMapProvider.overrideWith((ref) async => data)],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(
            style: registry.byId('zakhrafa'),
            mode: ThemeModeId.light,
            uiFont: UiFont.plex,
          ),
          home: const Scaffold(body: PagesMap(current: 7)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tokens = tester.element(find.byType(PagesMap)).tokens;

    Material cell(int page) => tester.widget<Material>(
      find
          .descendant(
            of: find.bySemanticsLabel(RegExp('^الصفحة ${_ar(page)}(،|\$)')),
            matching: find.byType(Material),
          )
          .first,
    );

    // Grouped by juz, each with a header.
    expect(find.text('الجزء ١'), findsOneWidget);
    expect(find.text('الجزء ٢'), findsOneWidget);
    // The legend names every state.
    for (final label in [
      'الصفحة الحالية',
      'مقروءة في الختمة',
      'فيها فاصل',
      'ضعيف',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }

    // Memorized: the hifz map's colour, whatever else.
    expect(cell(4).color, strengthFill(Strength.strong, ThemeModeId.light));
    expect(cell(5).color, strengthFill(Strength.weak, ThemeModeId.light));
    // Read, not memorized: a wash of the theme's control colour.
    final read = cell(3).color!;
    expect(read, isNot(tokens.colors.paper));
    expect(read, isNot(cell(1).color));
    // Nothing: plain paper.
    expect(cell(1).color, tokens.colors.paper);
    // The current page is ringed in the control colour.
    final ring = (cell(7).shape as RoundedRectangleBorder).side;
    expect(ring.color, tokens.colors.control);
    expect(ring.width, greaterThan(2));
    // A mark flags its page, in its colour.
    expect(
      find.descendant(
        of: find.bySemanticsLabel(RegExp('^الصفحة ٦')),
        matching: find.byWidgetPredicate(
          (w) => w is Icon && w.color == const Color(0xFF2E7D32),
        ),
      ),
      findsOneWidget,
    );
    // Screen readers hear each state.
    expect(
      find.bySemanticsLabel('الصفحة ٥، مقروءة في الختمة، ضعيف'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('الصفحة ٧، الصفحة الحالية'), findsOneWidget);
    // The juz header counts the pages read.
    expect(find.text('قُرئ ٢ من ٢١'), findsOneWidget);
  });
}

String _ar(int n) => '$n'
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();
