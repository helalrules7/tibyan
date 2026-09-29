import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/mushaf/presentation/about_mushaf_screen.dart';
import '../../features/mushaf/presentation/continuous_screen.dart';
import '../../features/mushaf/presentation/download_screen.dart';
import '../../features/mushaf/presentation/fawasil_screen.dart';
import '../../features/mushaf/presentation/index_screen.dart';
import '../../features/mushaf/presentation/mushaf_screen.dart';
import '../../features/onboarding/onboarding_edition_screen.dart';
import '../../features/onboarding/onboarding_language_screen.dart';
import '../../features/onboarding/onboarding_style_screen.dart';
import '../../features/settings/appearance_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../settings/settings_controller.dart';

int? _int(GoRouterState s, String key) =>
    int.tryParse(s.uri.queryParameters[key] ?? '');

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    // First launch: language, then style and colours, then the edition.
    redirect: (context, state) {
      final done = ref.read(settingsProvider).onboardingDone;
      final inOnboarding = state.matchedLocation.startsWith('/onboarding');
      if (!done && !inOnboarding) return '/onboarding/language';
      return null;
    },
    routes: [
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
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'appearance',
                builder: (context, state) => const AppearanceScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/mushaf',
        builder: (context, state) => MushafScreen(
          key: ValueKey(state.uri.toString()),
          initialPage: _int(state, 'page'),
          selectSurah: _int(state, 's'),
          selectAyah: _int(state, 'a'),
        ),
        routes: [
          GoRoute(
            path: 'download',
            builder: (context, state) => const DownloadScreen(),
          ),
          GoRoute(
            path: 'continuous',
            builder: (context, state) => ContinuousScreen(
              key: ValueKey(state.uri.toString()),
              surah: _int(state, 's') ?? 1,
              ayah: _int(state, 'a'),
            ),
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
            path: 'about',
            builder: (context, state) => const AboutMushafScreen(),
          ),
        ],
      ),
    ],
  ),
);
