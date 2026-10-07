import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/hifz/presentation/hifz_map_screen.dart';
import '../../features/hifz/presentation/hifz_screen.dart';
import '../../features/audio/audio_downloads_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/khatma/presentation/journal_screen.dart';
import '../../features/khatma/presentation/khatma_screen.dart';
import '../../features/khatma/presentation/new_khatma_screen.dart';
import '../../features/khatma/presentation/reports_screen.dart';
import '../../features/mushaf/presentation/about_mushaf_screen.dart';
import '../../features/mushaf/presentation/download_all_screen.dart';
import '../../features/mushaf/presentation/download_screen.dart';
import '../../features/mushaf/presentation/fawasil_screen.dart';
import '../../features/mushaf/presentation/index_screen.dart';
import '../../features/mushaf/data/tajweed.dart';
import '../../features/mushaf/presentation/mushaf_screen.dart';
import '../../features/mushaf/presentation/tajweed_index_screen.dart';
import '../../features/onboarding/onboarding_edition_screen.dart';
import '../../features/onboarding/onboarding_language_screen.dart';
import '../../features/onboarding/onboarding_style_screen.dart';
import '../../features/settings/appearance_screen.dart';
import '../../features/settings/player_settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tafsir/tafsir_screen.dart';
import '../../features/reading/continuous_screen.dart';
import '../../features/reading/one_verse_screen.dart';
import '../../features/tasmee/domain/tasmee_session_request.dart';
import '../../features/tasmee/presentation/tasmee_session_screen.dart';
import '../../features/tasmee/presentation/tasmee_setup_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/storage_screen.dart';
import '../settings/app_settings.dart';
import '../settings/settings_controller.dart';
import 'keyboard_dismiss.dart';

int? _int(GoRouterState s, String key) =>
    int.tryParse(s.uri.queryParameters[key] ?? '');

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/splash',
    // A screen left or returned to never keeps the keyboard up.
    observers: [KeyboardDismissObserver()],
    // First launch: language, then style and colours, then the edition.
    redirect: (context, state) {
      final done = ref.read(settingsProvider).onboardingDone;
      if (state.matchedLocation == '/splash') return null;
      final inOnboarding = state.matchedLocation.startsWith('/onboarding');
      // «Download all» is offered on the edition step too.
      final downloads = state.matchedLocation == '/downloads';
      if (!done && !inOnboarding && !downloads) return '/onboarding/language';
      return null;
    },
    routes: [
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadAllScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/tasmee',
        builder: (context, state) => const TasmeeSetupScreen(),
        routes: [
          GoRoute(
            path: 'session',
            builder: (context, state) {
              final request = state.extra;
              return request is TasmeeSessionRequest
                  ? TasmeeSessionScreen(request: request)
                  : const TasmeeSetupScreen();
            },
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding/language',
        builder: (context, state) => const OnboardingLanguageScreen(),
      ),
      GoRoute(
        path: '/onboarding/style',
        builder: (context, state) => const OnboardingStyleScreen(),
      ),
      GoRoute(
        path: '/onboarding/edition',
        builder: (context, state) => const OnboardingEditionScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'appearance',
                builder: (context, state) => const AppearanceScreen(),
              ),
              GoRoute(
                path: 'storage',
                builder: (context, state) => const StorageScreen(),
              ),
              GoRoute(
                path: 'player',
                builder: (context, state) => const PlayerSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/hifz',
        builder: (context, state) => const HifzScreen(),
        routes: [
          GoRoute(
            path: 'map',
            builder: (context, state) => const HifzMapScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/khatma',
        builder: (context, state) => const KhatmaScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const NewKhatmaScreen(),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: 'journal',
            builder: (context, state) => const JournalScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/verse',
        builder: (context, state) => OneVerseScreen(
          surah: _int(state, 's') ?? 1,
          ayah: _int(state, 'a') ?? 1,
        ),
      ),
      GoRoute(
        path: '/read',
        builder: (context, state) => ContinuousScreen(
          key: ValueKey(state.uri.toString()),
          surah: _int(state, 's') ?? 1,
          ayah: _int(state, 'a') ?? 1,
        ),
      ),
      GoRoute(
        path: '/mushaf',
        builder: (context, state) => MushafScreen(
          key: ValueKey(state.uri.toString()),
          initialPage: _int(state, 'page'),
          selectSurah: _int(state, 's'),
          selectAyah: _int(state, 'a'),
          hifzUnit: state.uri.queryParameters['hifz'],
          hifzFrom: state.uri.queryParameters['from'],
          hifzTo: state.uri.queryParameters['to'],
          listen: state.uri.queryParameters['listen'] == '1',
        ),
        routes: [
          GoRoute(
            path: 'download',
            builder: (context, state) => const DownloadScreen(),
          ),
          GoRoute(
            path: 'index',
            builder: (context, state) => IndexScreen(
              tab:
                  IndexTab.values
                      .asNameMap()[state.uri.queryParameters['tab']] ??
                  IndexTab.surahs,
              surah: _int(state, 's'),
              juz: _int(state, 'j'),
              hizb: _int(state, 'h'),
              page: _int(state, 'p'),
            ),
          ),
          GoRoute(
            path: 'fawasil',
            builder: (context, state) => const FawasilScreen(),
          ),
          GoRoute(
            path: 'tafsir',
            builder: (context, state) => TafsirScreen(
              surah: _int(state, 's') ?? 1,
              ayah: _int(state, 'a') ?? 1,
              riwaya: Riwaya.values.asNameMap()[state.uri.queryParameters['r']],
              riwayaAyah: _int(state, 'ra'),
            ),
          ),
          GoRoute(
            path: 'audio',
            builder: (context, state) => const AudioDownloadsScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutMushafScreen(),
            routes: [
              GoRoute(
                path: 'tajweed',
                builder: (context, state) => TajweedRuleScreen(
                  rule:
                      TajweedRule.byKey(
                        state.uri.queryParameters['rule'] ?? '',
                      ) ??
                      TajweedRule.madd6,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
