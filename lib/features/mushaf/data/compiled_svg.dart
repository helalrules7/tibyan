import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart' as vgc;

/// One SVG as a ready picture, compiled off the main isolate.
///
/// Parsing a mushaf page's SVG on the main isolate costs about 200 ms
/// (measured 203 ms for page 100, 643 KB of text), and every page turn paid
/// it before the first frame; a theme's art pieces cost 30-170 ms each. The
/// same page compiled to a vector_graphics binary costs the UI isolate 12 ms
/// and its fifteen line bands then draw in 54 ms instead of 81, the binary
/// carrying fewer operations than the parsed SVG.
///
/// The picture is not cached: the caller owns it and disposes it, as
/// [VectorGraphicUtilities.loadPicture] documents. Compiled bytes are not
/// cached either, so a page turned back to is compiled again — 26 ms on the
/// warm worker [SvgCompiler] keeps.
Future<PictureInfo> compiledSvgPicture(String svg, {required String name}) =>
    vg.loadPicture(_CompiledSvg(svg, name), null);

/// Compiles [svg] to the vector_graphics binary format, on the calling
/// isolate. [SvgCompiler] is what keeps that off the UI isolate.
///
/// The compiler's path-op optimisers are left off: they need Flutter's
/// libpath_ops, which is not shipped in an app — turning them on throws
/// "PathOps library was not initialized" — and on a page they changed the
/// drawing time by nothing (53.8 against 54.2 ms).
Uint8List compileSvg(String svg, String name) => vgc.encodeSvg(
  xml: svg,
  debugName: name,
  enableMaskingOptimizer: false,
  enableClippingOptimizer: false,
  enableOverdrawOptimizer: false,
);

/// Compiles SVGs on long-lived worker isolates.
///
/// A page compiles in 103 ms on an isolate that has not compiled one before,
/// and in 26 ms on one that has: the difference is the compiler's colour and
/// text caches, built as a side effect of the first page. Spawning an isolate
/// costs a millisecond, so the workers are spawned once and kept, and every
/// page after the first gets the warm price. Spawning one per page — what
/// this did first — threw those caches away every time.
///
/// There are two of them because a page asks for two pictures at once (the
/// page and its printed markers) and one worker answers in order: on a phone
/// those two would otherwise queue, doubling the time to the first frame.
///
/// If a worker cannot be started, or dies, compiling falls back to a fresh
/// isolate per call.
class SvgCompiler {
  SvgCompiler._();

  /// Two is what a page asks for at once, and the phone has cores to spare.
  static const _slots = 2;

  static final _inboxes = <int, SendPort>{};
  static final _isolates = <int, Isolate>{};
  static final _starting = <int, Future<SendPort?>>{};
  static final _pending = <int, Completer<Uint8List>>{};
  static var _next = 0;

  /// Compiles [svg] on a worker.
  static Future<Uint8List> compile(String svg, String name) async {
    // Round robin, so a page's two pictures go to two workers.
    final slot = _next++ % _slots;
    final inbox = await (_inboxes[slot] != null
        ? Future.value(_inboxes[slot])
        : (_starting[slot] ??= _spawn(slot)));
    if (inbox == null) {
      return Isolate.run(
        () => compileSvg(svg, name),
        debugName: 'compile $name',
      );
    }
    final id = _next++;
    final result = Completer<Uint8List>();
    _pending[id] = result;
    inbox.send([id, svg, name]);
    return result.future;
  }

  /// Stops the workers. Nothing in the app calls this; it is here for tests
  /// that would otherwise be kept alive by isolates they started.
  @visibleForTesting
  static void stop() {
    for (final isolate in _isolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _inboxes.clear();
    _starting.clear();
    _pending.clear();
  }

  static Future<SendPort?> _spawn(int slot) async {
    final hello = ReceivePort();
    final replies = ReceivePort();
    final Isolate isolate;
    try {
      isolate = await Isolate.spawn(_work, [
        hello.sendPort,
        replies.sendPort,
      ], debugName: 'svg compiler $slot');
    } on Object catch (e) {
      debugPrint('SvgCompiler: no worker ($e), compiling per page instead');
      hello.close();
      replies.close();
      return null;
    }
    final inbox = await hello.first as SendPort;
    hello.close();
    replies.listen(_collect);
    isolate.addOnExitListener(replies.sendPort, response: 'exit');
    _isolates[slot] = isolate;
    _inboxes[slot] = inbox;
    return inbox;
  }

  static void _collect(Object? message) {
    if (message == 'exit') {
      // A worker went away: fail whatever is queued, and let the next
      // compile spawn a new one rather than waiting on a port nobody reads.
      for (final waiting in _pending.values) {
        waiting.completeError(StateError('the SVG compiler stopped'));
      }
      _pending.clear();
      _isolates.clear();
      _inboxes.clear();
      _starting.clear();
      return;
    }
    final reply = message as List<Object?>;
    final waiting = _pending.remove(reply[0] as int);
    if (waiting == null) return;
    final bytes = reply[1] as Uint8List?;
    if (bytes == null) {
      waiting.completeError(StateError('could not compile an SVG'));
    } else {
      waiting.complete(bytes);
    }
  }

  /// The worker's own loop: answer with its port, then compile what it is
  /// sent, one at a time.
  static void _work(List<SendPort> ports) {
    final inbox = ReceivePort();
    ports[0].send(inbox.sendPort);
    inbox.listen((Object? message) {
      final request = message as List<Object?>;
      Uint8List? bytes;
      try {
        bytes = compileSvg(request[1] as String, request[2] as String);
      } on Object catch (e) {
        debugPrint('SvgCompiler: ${request[2]} failed ($e)');
      }
      ports[1].send([request[0], bytes]);
    });
  }
}

@immutable
class _CompiledSvg extends BytesLoader {
  const _CompiledSvg(this.svg, this.name);

  final String svg;
  final String name;

  @override
  Future<ByteData> loadBytes(BuildContext? context) async {
    final bytes = await SvgCompiler.compile(svg, name);
    return ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
  }

  /// The compiled bytes depend on the SVG alone, so a widget that shows the
  /// same page twice asks the compiler for it once.
  @override
  Object cacheKey(BuildContext? context) => svg;

  @override
  String toString() => 'CompiledSvg($name)';
}
