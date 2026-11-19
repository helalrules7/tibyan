import 'dart:async';

import 'core/downloads/cellular_banner.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ui/responsive.dart';
import 'core/router/app_router.dart';
import 'core/router/keyboard_dismiss.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/mac_menu.dart';
import 'features/audio/global_player.dart';
import 'features/home_widgets/widget_look_sync.dart';
import 'features/sync/sync_controller.dart';
import 'features/tasbih/tasbih_providers.dart' show watchCountsProvider;
import 'l10n/app_localizations.dart';

class TibyanApp extends ConsumerWidget {
  const TibyanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only what the app's theme and language are made of: changing any
    // other setting does not build the whole app again.
    final settings = ref.watch(
      settingsProvider.select(
        (s) => (
          styleId: s.styleId,
          mode: s.mode,
          locale: s.locale,
          uiFont: s.uiFont,
          elderlyMode: s.elderlyMode,
          forceReduceMotion: s.forceReduceMotion,
          interfaceStyle: s.interfaceStyle,
        ),
      ),
    );
    final registry = ref.watch(themeRegistryProvider);
    final style = registry.byId(settings.styleId);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final mode = ref.read(settingsProvider).resolveMode(platformBrightness);
    // The home screen widgets set to «كما في التطبيق» follow the look and
    // the language (their pictures are drawn after the frame, when needed).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(widgetLookSyncProvider)
            .follow(
              style: settings.interfaceStyle,
              mode: mode,
              l: lookupAppLocalizations(settings.locale ?? const Locale('ar')),
            ),
      );
    });

    // «المزامنة» runs from the start (when switched on) without building
    // the app again on its status.
    ref.listen(cloudSyncProvider, (_, _) {});
    // Watch counts join the misbaha at once, on any screen.
    ref.listen(watchCountsProvider, (_, _) {});
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      scrollBehavior: const AppScrollBehavior(),
      // A tap outside a text field closes the keyboard.
      actions: {...WidgetsApp.defaultActions, ...tapOutsideActions()},
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(
        style: style,
        mode: mode,
        uiFont: settings.uiFont,
        elderly: settings.elderlyMode,
        interfaceStyle: settings.interfaceStyle,
      ),
      // The player on every screen while a recitation plays; elderly
      // mode: text at least a quarter larger, whatever the device asks for
      // (a larger system size is kept).
      builder: (context, child) {
        // Downloads held on mobile data ask here, over every screen.
        final player = CellularDownloadsBanner(
          child: MacMenu(
            router: router,
            child: GlobalPlayer(router: router, child: child!),
          ),
        );
        if (!settings.elderlyMode && !settings.forceReduceMotion) {
          return player;
        }
        return MediaQuery(
          data: appMediaQuery(
            MediaQuery.of(context),
            elderly: settings.elderlyMode,
            reduceMotion: settings.forceReduceMotion,
          ),
          child: player,
        );
      },
    );
  }
}

/// The device's [mq] as the app's own settings change it: elderly mode
/// reads text at least a quarter larger (a larger system size is kept);
/// «تقليل الحركة» turns animations off whatever the device asks.
MediaQueryData appMediaQuery(
  MediaQueryData mq, {
  required bool elderly,
  required bool reduceMotion,
}) {
  final scale = mq.textScaler.scale(1);
  return mq.copyWith(
    textScaler: elderly && scale < elderlyTextScale
        ? const TextScaler.linear(elderlyTextScale)
        : mq.textScaler,
    disableAnimations: reduceMotion || mq.disableAnimations,
  );
}
