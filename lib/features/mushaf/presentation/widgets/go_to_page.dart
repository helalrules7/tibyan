import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import 'illuminated_frame.dart' show NumberFormatter;

/// Asks for a page number from 1 to [max] (604 in the Madina editions);
/// returns it, or null if cancelled.
Future<int?> showGoToPage(
  BuildContext context, {
  required int current,
  int max = 604,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) => _GoToPageDialog(current: current, max: max),
  );
}

class _GoToPageDialog extends StatefulWidget {
  const _GoToPageDialog({required this.current, required this.max});

  final int current;
  final int max;

  @override
  State<_GoToPageDialog> createState() => _GoToPageDialogState();
}

class _GoToPageDialogState extends State<_GoToPageDialog> {
  /// Digits as the interface writes them: Arabic-Indic in Arabic.
  late final _digits = NumberFormatter(Localizations.localeOf(context));
  late final _field = TextEditingController(text: _digits(widget.current));

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  int? get _value {
    final n = int.tryParse(latinDigits(_field.text.trim()));
    return n != null && n >= 1 && n <= widget.max ? n : null;
  }

  void _step(int by) {
    final n = ((_value ?? widget.current) + by).clamp(1, widget.max);
    setState(() => _field.text = _digits(n));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens.colors;
    final hint = l.goToPageHint(
      NumberFormatter(Localizations.localeOf(context))(widget.max),
    );
    return AlertDialog(
      title: Text(l.goToPage, textAlign: TextAlign.center),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            tooltip: l.previousPageNumber,
            onPressed: () => _step(-1),
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _field,
              autofocus: true,
              textAlign: TextAlign.center,
              // Digits only, typed in either set, shown in the
              // interface's own.
              keyboardType: TextInputType.number,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.go,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩۰-۹]')),
                LengthLimitingTextInputFormatter('${widget.max}'.length),
                AppDigitsFormatter(
                  arabic: Localizations.localeOf(context).languageCode == 'ar',
                ),
              ],
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: t.ink,
              ),
              decoration: InputDecoration(
                labelText: hint,
                errorText: _field.text.isNotEmpty && _value == null
                    ? hint
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_value != null) Navigator.of(context).pop(_value);
              },
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: l.nextPageNumber,
            onPressed: () => _step(1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _value == null
              ? null
              : () => Navigator.of(context).pop(_value),
          child: Text(l.goLabel),
        ),
      ],
    );
  }
}

/// [text] with Arabic-Indic (and Persian) digits as Western ones.
String latinDigits(String text) =>
    text.replaceAllMapped(RegExp('[٠-٩۰-۹]'), (m) {
      final c = m[0]!.codeUnitAt(0);
      return '${c - (c >= 0x06F0 ? 0x06F0 : 0x0660)}';
    });

/// Writes the digits typed, in either set, as the interface writes them:
/// Arabic-Indic when [arabic], Western otherwise.
class AppDigitsFormatter extends TextInputFormatter {
  AppDigitsFormatter({required this.arabic});

  final bool arabic;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final latin = latinDigits(newValue.text);
    final text = arabic
        ? latin.replaceAllMapped(
            RegExp('[0-9]'),
            (m) => String.fromCharCode(0x0660 + int.parse(m[0]!)),
          )
        : latin;
    if (text == newValue.text) return newValue;
    // One character for one: the selection stays where it was.
    return newValue.copyWith(text: text);
  }
}
