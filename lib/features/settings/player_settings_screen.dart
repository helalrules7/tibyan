import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../audio/player_bar.dart';

/// The listening options, kept for the next time: the same as in the
/// player's sheet, reached from the settings.
class PlayerSettingsScreen extends StatelessWidget {
  const PlayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).playerSettings)),
    body: const Padding(
      padding: EdgeInsets.only(top: 8),
      child: PlayerOptions(inSheet: false),
    ),
  );
}
