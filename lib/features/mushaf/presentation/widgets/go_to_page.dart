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
  late final _field = TextEditingController(text: '${widget.current}');

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  int? get _value {
    final latin = _field.text.trim().replaceAllMapped(
      RegExp('[٠-٩]'),
      (m) => '${m[0]!.codeUnitAt(0) - 0x0660}',
    );
    final n = int.tryParse(latin);
    return n != null && n >= 1 && n <= widget.max ? n : null;
  }

  void _step(int by) {
    final n = ((_value ?? widget.current) + by).clamp(1, widget.max);
    setState(() => _field.text = '$n');
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
            tooltip: '−',
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
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]')),
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
            tooltip: '+',
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
