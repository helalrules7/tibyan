import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The focused text field's context, or null when nothing is being typed
/// (the keyboard is down, or focus is on a button).
BuildContext? _typingIn() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null || !context.mounted) return null;
  final field =
      context.widget is EditableText ||
      context.findAncestorWidgetOfExactType<EditableText>() != null;
  return field ? context : null;
}

/// Closes the keyboard: the text field being typed in loses its focus.
/// Focus on anything else (a button reached with a hardware keyboard) is
/// left where it is.
void dismissKeyboard() {
  if (_typingIn() != null) FocusManager.instance.primaryFocus?.unfocus();
}

/// Closes the keyboard whenever the screen changes: a screen pushed over
/// a text field takes the keyboard down with it, and a screen returned to
/// does not get it back. A screen that is opened and focuses its own field
/// (search) keeps it.
class KeyboardDismissObserver extends NavigatorObserver {
  /// Routes opened since the last frame: a field they focused themselves
  /// stays focused.
  final _opened = <Route<dynamic>>{};
  bool _scheduled = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    dismissKeyboard();
    _opened.add(route);
    _afterFrame();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    dismissKeyboard();
    if (newRoute != null) _opened.add(newRoute);
    _afterFrame();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _afterFrame();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _afterFrame();

  /// The screen uncovered gives its field back the focus it had: take it
  /// away once that is done, unless the field belongs to a screen just
  /// opened.
  void _afterFrame() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final opened = {..._opened};
      _opened.clear();
      final field = _typingIn();
      if (field == null) return;
      if (opened.contains(ModalRoute.of(field))) return;
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }
}

/// A tap outside the text field being typed in closes the keyboard; a drag
/// (scrolling a list under it) does not. Mouse clicks outside keep the
/// platform's own behaviour (they close it).
Map<Type, Action<Intent>> tapOutsideActions() {
  final down = _TapOutsideDown();
  return {
    EditableTextTapOutsideIntent: down,
    EditableTextTapUpOutsideIntent: _TapOutsideUp(down),
  };
}

class _TapOutsideDown extends Action<EditableTextTapOutsideIntent> {
  Offset? position;

  @override
  void invoke(EditableTextTapOutsideIntent intent) {
    final event = intent.pointerDownEvent;
    if (event.kind == PointerDeviceKind.touch) {
      // Decided on the finger's release: a tap, or the start of a drag.
      position = event.position;
    } else {
      position = null;
      intent.focusNode.unfocus();
    }
  }
}

class _TapOutsideUp extends Action<EditableTextTapUpOutsideIntent> {
  _TapOutsideUp(this.down);

  final _TapOutsideDown down;

  @override
  void invoke(EditableTextTapUpOutsideIntent intent) {
    final start = down.position;
    down.position = null;
    if (start == null) return;
    if ((intent.pointerUpEvent.position - start).distance <= kTouchSlop) {
      intent.focusNode.unfocus();
    }
  }
}

/// Closes the keyboard when the reader swipes to another tab or page:
/// the field left behind is no longer on screen.
class DismissKeyboardOnSwipe extends StatelessWidget {
  const DismissKeyboardOnSwipe({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (n) {
        if (n.dragDetails != null && n.metrics.axis == Axis.horizontal) {
          dismissKeyboard();
        }
        return false;
      },
      child: child,
    );
  }
}
