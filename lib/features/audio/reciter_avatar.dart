import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The same reader's recitation in another riwaya uses that reader's photo:
/// al-Husary (Warsh, Qalun, al-Duri) and Abdul Basit (Warsh).
const _photoOf = {101: 2, 111: 2, 121: 2, 106: 3};

/// A reciter's photo beside their name, or their initials while there is
/// no photo for them.
///
/// The photos are 128 px WebP (about 6 KB each; see
/// `tools/build_reciter_photos.py`), asked for at the size they are drawn
/// and cached by Flutter after the first decode, so a list of them costs
/// neither the app's size nor a frame.
class ReciterAvatar extends StatelessWidget {
  const ReciterAvatar({
    super.key,
    required this.id,
    required this.name,
    this.size = 40,
  });

  /// The reciter's id in content.db; the photo is `assets/reciters/<id>.webp`.
  final int id;
  final String name;
  final double size;

  /// The first letter of the first two words of the name.
  String get _initials {
    final words = name.trim().split(RegExp(r'\s+'));
    return [
      for (final w in words.take(2))
        if (w.isNotEmpty) w.characters.first,
    ].join();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens.colors;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.asset(
          'assets/reciters/${_photoOf[id] ?? id}.webp',
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * dpr).round(),
          filterQuality: FilterQuality.medium,
          // No photo for this reciter (or it has not been added yet): the
          // name's initials, as every other place in the app shows them.
          // Beside the reciter's name, so not read aloud again.
          excludeFromSemantics: true,
          errorBuilder: (context, _, _) => ExcludeSemantics(
            child: ColoredBox(
              color: t.accent,
              child: Center(
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontSize: size * 0.38,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: t.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
