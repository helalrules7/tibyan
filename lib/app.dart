import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

class TibyanApp extends ConsumerWidget {
  const TibyanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final registry = ref.watch(themeRegistryProvider);
    final style = registry.byId(settings.styleId);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final mode = settings.resolveMode(platformBrightness);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
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
      ),
      // Elderly mode: text at least a quarter larger, whatever the device
      // asks for (a larger system size is kept).
      builder: settings.elderlyMode
          ? (context, child) {
              final mq = MediaQuery.of(context);
              final scale = mq.textScaler.scale(1);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(
                    scale < elderlyTextScale ? elderlyTextScale : scale,
                  ),
                ),
                child: child!,
              );
            }
          : null,
    );
  }
}
