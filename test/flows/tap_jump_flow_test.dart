import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tibyan/app.dart';
import 'package:tibyan/core/db/content_database.dart';
import 'package:tibyan/core/db/user_database.dart';
import 'package:tibyan/core/flags/feature_flags.dart';
import 'package:tibyan/core/router/app_router.dart';
import 'package:tibyan/core/settings/settings_controller.dart';
import 'package:tibyan/core/theme/theme_registry.dart';
import 'package:tibyan/features/audio/recitation.dart';
import 'package:tibyan/features/home/whats_new.dart';
import 'package:tibyan/features/mushaf/mushaf_providers.dart';
import 'package:tibyan/features/mushaf/presentation/widgets/mushaf_page.dart';

/// Listening to al-Falaq, playing; records the jumps asked of it and
/// answers each with [result].
class FakeRecitation extends RecitationController {
  FakeRecitation(this.result, {this.active = true});

  final VerseJump result;
  final bool active;
  final jumps = <(int, int, int?)>[];

  @override
  RecitationState build() => RecitationState(
    active: active,
    playing: active,
    surah: 113,
    ayah: 1,
    timed: true,
  );

  @override
  Future<VerseJump> jumpTo(int surah, int ayah, {int? word}) async {
    jumps.add((surah, ayah, word));
    return result;
  }
}

/// A tap on a verse while listening moves the recitation there; a tap off
/// the text still shows the tools.
void main() {
  late ContentDatabase db;
  late Directory root;
  setUpAll(() {
    db = ContentDatabase(
      NativeDatabase(
        File('assets/db/content.db'),
        setup: (raw) => raw.execute('PRAGMA query_only = ON'),
      ),
    );
    root = Directory.systemTemp.createTempSync('tapjump');
    final dir = Directory(p.join(root.path, 'packs', 'pages-hafs-1441-v1'))
      ..createSync(recursive: true);
    final zip = ZipDecoder().decodeBytes(
      File('assets/packs/pages-hafs-1441-v1.zip').readAsBytesSync(),
    );
    for (final name in ['603.svg.xz', '604.svg.xz']) {
      final entry = zip.findFile(name)!;
      File(p.join(dir.path, entry.name)).writeAsBytesSync(entry.content);
    }
    File(p.join(dir.path, '.installed')).writeAsStringSync('test');
  });
  tearDownAll(() => db.close());

  Future<ProviderContainer> start(
    WidgetTester tester,
    FakeRecitation recitation,
  ) async {
    for (final m in ['toggle', 'isEnabled']) {
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$m',
        (_) async => const StandardMessageCodec().encodeMessage(<Object?>[
          m == 'isEnabled' ? false : null,
        ]),
      );
    }
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
      'settings.language': 'ar',
      whatsNewSeenKey: whatsNewId,
    });
    final registry = (await tester.runAsync(
      () => ThemeRegistry.load(rootBundle),
    ))!;
    final flags = (await tester.runAsync(() => FeatureFlags.load(rootBundle)))!;
    final prefs = await SharedPreferences.getInstance();
    final user = UserDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(user.close));
    // Wide enough for the tools' bar in the test font.
    await tester.binding.setSurfaceSize(const Size(600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        themeRegistryProvider.overrideWithValue(registry),
        featureFlagsProvider.overrideWithValue(flags),
        sharedPreferencesProvider.overrideWithValue(prefs),
        contentDatabaseProvider.overrideWithValue(db),
        userDatabaseProvider.overrideWithValue(user),
        packRootProvider.overrideWithValue(root),
        readingPositionProvider.overrideWith((ref) => Stream.value(null)),
        recitationProvider.overrideWith(() => recitation),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TibyanApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    container.read(appRouterProvider).go('/mushaf?page=604');
    return container;
  }

  Future<void> settle(WidgetTester tester, [Finder? until]) async {
    for (var i = 0; i < 40; i++) {
      if (until != null && until.evaluate().isNotEmpty) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The screen reader's node of al-Falaq's verse [n].
  Finder falaq(int n) =>
      find.bySemanticsLabel(RegExp('الفلق.*${'٠١٢٣٤٥٦٧٨٩'[n]}'));

  testWidgets('a verse tap jumps there; a tap off the text shows the tools', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final recitation = FakeRecitation(VerseJump.jumped);
    await start(tester, recitation);
    await settle(tester, falaq(2));
    expect(falaq(2), findsWidgets);
    await settle(tester); // the page's words, for touches

    // Verse 2 sits on one line: the middle of its area is on its words.
    await tester.tapAt(tester.getRect(falaq(2).first).center);
    await tester.pump();
    expect(recitation.jumps, [(113, 2, null)]);
    expect(find.byIcon(Icons.list_alt), findsNothing, reason: 'no tools');

    // The page's margin, off the text: the tools, and no jump.
    final page = tester.getRect(find.byType(MushafPage).first);
    await tester.tapAt(page.topLeft + const Offset(4, 4));
    await tester.pump();
    expect(recitation.jumps, hasLength(1));
    expect(find.byIcon(Icons.list_alt), findsWidgets);

    // Screen readers: «استمع من هذه الآية» on each verse.
    final node = tester.getSemantics(falaq(4).first);
    final action = node.getSemanticsData().customSemanticsActionIds!.map(
      CustomSemanticsAction.getAction,
    );
    final listen = action.firstWhere((a) => a?.label == 'استمع من هذه الآية');
    tester.binding.performSemanticsAction(
      SemanticsActionEvent(
        type: SemanticsAction.customAction,
        viewId: tester.view.viewId,
        nodeId: node.id,
        arguments: CustomSemanticsAction.getIdentifier(listen!),
      ),
    );
    await tester.pump();
    expect(recitation.jumps.last, (113, 4, null));
    handle.dispose();
  });

  testWidgets('a recitation without timings says so and stays', (tester) async {
    final handle = tester.ensureSemantics();
    final recitation = FakeRecitation(VerseJump.noTiming);
    await start(tester, recitation);
    await settle(tester, falaq(5));
    await settle(tester);
    await tester.tapAt(tester.getRect(falaq(5).first).center);
    await tester.pump();
    await tester.pump();
    expect(recitation.jumps, [(113, 5, null)]);
    expect(find.text('هذه التلاوة لا تدعم الانتقال إلى آية'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('not listening, a verse tap does what it did', (tester) async {
    final handle = tester.ensureSemantics();
    final recitation = FakeRecitation(VerseJump.jumped, active: false);
    await start(tester, recitation);
    await settle(tester, falaq(2));
    await settle(tester);
    // No action to listen from a verse either.
    final node = tester.getSemantics(falaq(2).first);
    final labels = node.getSemanticsData().customSemanticsActionIds!.map(
      (id) => CustomSemanticsAction.getAction(id)?.label,
    );
    expect(labels, isNot(contains('استمع من هذه الآية')));
    // Touch reading (on by default) shades the verse: no jump, no tools.
    await tester.tapAt(tester.getRect(falaq(2).first).center);
    await tester.pump();
    expect(recitation.jumps, isEmpty);
    expect(find.byIcon(Icons.list_alt), findsNothing);
    handle.dispose();
  });
}
