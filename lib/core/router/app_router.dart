import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/settings/appearance_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  routes: [
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
  ],
);
