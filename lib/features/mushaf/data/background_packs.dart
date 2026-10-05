import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

import '../../books/data/book_pack.dart';
import 'page_pack.dart';

/// Page packs downloaded by the system (WorkManager / a user-initiated job
/// on Android, a background URLSession on iOS), so a download goes on when
/// the reader leaves the app, with a notification while it runs and when
/// it ends. The app checks and installs a finished pack when it next runs.
class BackgroundPacks {
  BackgroundPacks({required this.root, FileDownloader? downloader})
    : _dl = downloader ?? FileDownloader();

  static const group = 'packs';

  /// Where packs are installed (same as [PagePackInstaller.root]).
  final Directory root;
  final FileDownloader _dl;

  final _progress = StreamController<(String, PackProgress)>.broadcast();
  final _installing = <String>{};
  StreamSubscription<TaskUpdate>? _sub;

  /// Progress of each pack, keyed by pack id.
  Stream<(String, PackProgress)> get progress => _progress.stream;

  /// Notification texts, in the interface language.
  static ({String running, String complete, String error, String paused})
  texts = (
    running: 'تحميل صفحات المصحف',
    complete: 'اكتمل تحميل المصحف',
    error: 'تعذّر تحميل المصحف',
    paused: 'التحميل متوقف مؤقتا',
  );

  /// Starts tracking: call once at startup. Packs that finished while the
  /// app was closed are installed now.
  Future<void> start() async {
    _dl
      ..configureNotificationForGroup(
        group,
        running: TaskNotification(texts.running, '{displayName}'),
        complete: TaskNotification(texts.complete, '{displayName}'),
        error: TaskNotification(texts.error, '{displayName}'),
        paused: TaskNotification(texts.paused, '{displayName}'),
        progressBar: true,
      )
      // Android before 14: a foreground service lifts the 9-minute limit.
      ..configure(androidConfig: [(Config.runInForeground, Config.always)]);
    _sub ??= _dl.updates.listen(_onUpdate);
    await _dl.start();
    for (final r in await _dl.database.allRecords(group: group)) {
      if (r.status == TaskStatus.complete && r.task is DownloadTask) {
        await _install(r.task as DownloadTask);
      }
    }
  }

  PagePackSpec? _spec(String id) {
    for (final s in [
      ...PagePackSpec.all,
      for (final b in BookPackSpec.all) b.pack,
    ]) {
      if (s.id == id) return s;
    }
    return null;
  }

  PagePackInstaller _installer(PagePackSpec spec) =>
      PagePackInstaller(root: root, spec: spec);

  /// Queues a pack (the mirror first, then its fallbacks on failure).
  /// Nothing happens when it is installed or already running; a paused
  /// one resumes.
  Future<void> enqueue(PagePackSpec spec, String displayName) async {
    if (_installer(spec).isInstalled) {
      _progress.add((spec.id, const PackProgress(PackPhase.installed)));
      return;
    }
    final existing = await _dl.taskForId(spec.id);
    if (existing != null) {
      if (existing is DownloadTask) await _dl.resume(existing);
      return;
    }
    await _dl.enqueue(_task(spec, displayName, 0));
    // Ask for notifications without holding the download on the answer.
    unawaited(
      _dl.permissions
          .request(PermissionType.notifications)
          .catchError((_) => PermissionStatus.denied),
    );
  }

  DownloadTask _task(PagePackSpec spec, String displayName, int source) =>
      DownloadTask(
        taskId: spec.id,
        url: [spec.url, ...spec.fallbacks][source],
        filename: '${spec.id}.zip',
        directory: 'pack-downloads',
        baseDirectory: BaseDirectory.applicationSupport,
        group: group,
        updates: Updates.statusAndProgress,
        allowPause: true,
        retries: 3,
        displayName: displayName,
        metaData: '$source',
        transferHints: {TransferHint.userInitiated, TransferHint.largeFile},
      );

  Future<void> pause(PagePackSpec spec) async {
    final t = await _dl.taskForId(spec.id);
    if (t is DownloadTask) await _dl.pause(t);
  }

  Future<void> resume(PagePackSpec spec) async {
    final t = await _dl.taskForId(spec.id);
    if (t is DownloadTask) await _dl.resume(t);
  }

  /// The latest known state of a pack, from the downloader's records.
  Future<PackProgress> stateOf(PagePackSpec spec) async {
    if (_installer(spec).isInstalled) {
      return const PackProgress(PackPhase.installed);
    }
    final r = await _dl.database.recordForId(spec.id);
    if (r == null) return const PackProgress(PackPhase.idle);
    final received = (r.progress.clamp(0, 1) * spec.bytes).round();
    return switch (r.status) {
      TaskStatus.running ||
      TaskStatus.enqueued ||
      TaskStatus.waitingToRetry => PackProgress(
        PackPhase.downloading,
        received: received,
        total: spec.bytes,
      ),
      TaskStatus.paused => PackProgress(
        PackPhase.idle,
        received: received,
        total: spec.bytes,
      ),
      TaskStatus.complete => const PackProgress(PackPhase.installing),
      _ => const PackProgress(PackPhase.idle),
    };
  }

  Future<void> _onUpdate(TaskUpdate update) async {
    final task = update.task;
    if (task.group != group || task is! DownloadTask) return;
    final spec = _spec(task.taskId);
    if (spec == null) return;
    switch (update) {
      case TaskProgressUpdate(:final progress):
        if (progress < 0) return;
        _progress.add((
          spec.id,
          PackProgress(
            PackPhase.downloading,
            received: (progress * spec.bytes).round(),
            total: spec.bytes,
          ),
        ));
      case TaskStatusUpdate(:final status, :final exception):
        switch (status) {
          case TaskStatus.complete:
            await _install(task);
          case TaskStatus.failed || TaskStatus.notFound:
            // Try the next source, if there is one.
            final next = (int.tryParse(task.metaData) ?? 0) + 1;
            if (next <= spec.fallbacks.length) {
              await _dl.enqueue(_task(spec, task.displayName, next));
            } else {
              _progress.add((
                spec.id,
                PackProgress(
                  PackPhase.failed,
                  error: exception?.description ?? status.name,
                ),
              ));
            }
          case TaskStatus.paused:
            _progress.add((spec.id, await stateOf(spec)));
          case TaskStatus.canceled:
            _progress.add((spec.id, const PackProgress(PackPhase.idle)));
          default:
            break;
        }
    }
  }

  Future<void> _install(DownloadTask task) async {
    final spec = _spec(task.taskId);
    if (spec == null || !_installing.add(spec.id)) return;
    try {
      final installer = _installer(spec);
      if (!installer.isInstalled) {
        final file = File(await task.filePath());
        if (!file.existsSync()) return;
        _progress.add((spec.id, const PackProgress(PackPhase.verifying)));
        await installer.installFrom(file);
      }
      await _dl.database.deleteRecordWithId(spec.id);
      _progress.add((spec.id, const PackProgress(PackPhase.installed)));
    } catch (e) {
      await _dl.database.deleteRecordWithId(spec.id);
      _progress.add((spec.id, PackProgress(PackPhase.failed, error: '$e')));
    } finally {
      _installing.remove(spec.id);
    }
  }
}
