import 'package:background_tasks/background_tasks.dart';
import 'package:core_ports/core_ports.dart';
import 'package:get_it/get_it.dart';
import 'package:sync_api/sync_api.dart';

/// The name this app schedules its outbox drain under.
///
/// A string a composition root chose, and it has to be one: what the operating
/// system hands back is a name, and `platform/background_tasks` may not know
/// what a sync is. It is namespaced because both platforms keep task
/// identifiers in a space shared with everything else the app registers.
const String drainTaskName = 'peyk.sync.drain';

/// How often the operating system is asked to consider a drain.
///
/// The floor, and not because shorter would be better. A drain that never
/// happens loses no work — the outbox is durable and the review screen can
/// still start one by hand — so this is the cheapest useful setting rather
/// than a guarantee. iOS may ignore it for days, and that is allowed to be
/// true without anything breaking.
const Duration drainInterval = BackgroundScheduler.minimumInterval;

/// What one background invocation of [name] does.
///
/// **This is the half of background work this repository can test.** The other
/// half — the `@pragma('vm:entry-point')` function the operating system calls
/// into — needs `android/`, `ios/` and a native process, none of which the
/// specification asks this repository to build. Keeping the decision in an
/// ordinary function over an ordinary container is what leaves the untestable
/// part down to six lines that only build one.
///
/// The answer is what the platform does next, so the mapping matters:
///
/// - a drain that returned a status is `true`, **including one where every
///   entry failed to send**. The queue has its own retry schedule, and asking
///   WorkManager to retry as well would stack two backoffs over one queue —
///   the entries would be attempted on the platform's timetable rather than on
///   the one `RetrySchedule` computed.
/// - a drain that returned a `SyncFailure` is `false`. `DrainOutbox` only
///   fails that way when the *store* could not be read or written, which is a
///   task that genuinely did not run, and a locked database is exactly the
///   kind of thing that is worth trying again later.
Future<bool> runBackgroundTask(String name, GetIt container) async {
  final logger = container<Logger>();

  if (name != drainTaskName) {
    // An unknown name is a schedule left behind by an older build. `true`
    // rather than `false`, because a name this version does not know is not
    // going to start working on a retry.
    logger.warning('a background task nobody claims', context: {'task': name});
    return true;
  }

  final drained = await container<SyncFacade>().drain();
  return drained.fold(
    (status) {
      logger.debug('background drain', context: {'status': '$status'});
      return true;
    },
    (failure) {
      logger.warning('background drain refused', context: {'why': '$failure'});
      return false;
    },
  );
}
