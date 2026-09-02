@Tags(['widget'])
library;

import 'package:app_courier/main.dart';
import 'package:background_tasks/background_tasks.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sync_api/sync_api.dart';

import 'support/test_platform.dart';

/// Whether anything happens while this app is not running.
///
/// `platform/` held nine packages and none of them scheduled work, so every
/// trigger in `SyncOrchestrator` needed the process to be alive: a courier who
/// force-quit in a basement sent nothing until they reopened the app.
///
/// This is the half of background work a test can reach. The other half — the
/// `@pragma('vm:entry-point')` dispatcher — needs `android/`, `ios/` and a
/// native process, and it is six lines precisely so that everything else is
/// down here.
void main() {
  // `SyncOrchestrator.start` builds an `AppLifecycleListener`, which reads
  // `WidgetsBinding.instance`. These are plain tests rather than widget ones
  // because nothing here draws anything, so the binding has to be asked for
  // explicitly.
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetIt container;

  setUp(() async {
    container = await configureCourier(testPlatform());
  });

  tearDown(() => container.reset());

  SyncOrchestrator orchestratorWith(BackgroundScheduler scheduler) =>
      SyncOrchestrator(
        sync: container<SyncFacade>(),
        network: container<NetworkStatus>(),
        logger: container<Logger>(),
        scheduler: scheduler,
      );

  group('what the app asks the operating system for', () {
    test('a periodic drain, on every start', () async {
      final scheduler = FakeBackgroundScheduler();
      final orchestrator = orchestratorWith(scheduler);
      addTearDown(orchestrator.dispose);

      orchestrator.start();
      await pumpEventQueue();

      final task = scheduler.taskNamed(drainTaskName);
      expect(task, isNotNull);
      expect(task!.isPeriodic, isTrue);
      expect(task.interval, drainInterval);
      // Waking to find no connection spends a courier's battery on a drain
      // that returns immediately.
      expect(task.constraints.networkRequired, isTrue);
    });

    test('starting twice leaves one schedule', () async {
      // The contract's replace-rather-than-append, relied on here: an app
      // schedules on every launch and a device must not accumulate tasks.
      final scheduler = FakeBackgroundScheduler();
      final orchestrator = orchestratorWith(scheduler);
      addTearDown(orchestrator.dispose);

      orchestrator
        ..start()
        ..start();
      await pumpEventQueue();

      expect(scheduler.tasks, hasLength(1));
    });

    test('a device that refuses still runs everything else', () async {
      // Background execution is the one trigger of the four a person can
      // switch off in the system settings. Treating that as an error would
      // report a preference as a fault.
      final scheduler = FakeBackgroundScheduler()
        ..nextFailure = const SchedulingRefused(
          code: 'BGTaskSchedulerErrorDomainNotPermitted',
        );
      final orchestrator = orchestratorWith(scheduler);
      addTearDown(orchestrator.dispose);

      orchestrator.start();
      await pumpEventQueue();

      expect(scheduler.tasks, isEmpty);
      // And the foreground path still works, which is the point of the
      // refusal being survivable.
      await orchestrator.drainNow();
    });

    test('an app with no scheduler schedules nothing', () async {
      // How `app_dispatcher` composes: a desk is at a connection and its
      // outbox is in memory, so there is nothing to send while it is closed.
      final orchestrator = SyncOrchestrator(
        sync: container<SyncFacade>(),
        network: container<NetworkStatus>(),
        logger: container<Logger>(),
      );
      addTearDown(orchestrator.dispose);

      orchestrator.start();
      await pumpEventQueue();
      // Nothing to assert but that it did not throw: the absence is the
      // behaviour, and a null scheduler is the only way to express it.
      expect(orchestrator.drainNow(), completes);
    });

    test('the app composes a real scheduler', () {
      // The gap the integration audit is about: an adapter can be perfect and
      // unused. This asserts the app registers one at all.
      expect(container.isRegistered<BackgroundScheduler>(), isTrue);
      expect(container<BackgroundScheduler>(), isA<WorkManagerScheduler>());
    });
  });

  group('what one background invocation does', () {
    test('a drain that ran is a task that succeeded', () async {
      expect(await runBackgroundTask(drainTaskName, container), isTrue);
    });

    test('a store that cannot be read is a task to try again', () async {
      // The only way `drain` answers a failure: `DrainOutbox` absorbs every
      // transport failure into the queue's own retry schedule and reports a
      // `SyncFailure` when the *store* would not answer. A locked database is
      // worth another go later; a failed request is not, because asking
      // WorkManager to retry would stack a second backoff over the queue's.
      await container.unregister<SyncFacade>();
      container.registerSingleton<SyncFacade>(_RefusingSync());

      expect(await runBackgroundTask(drainTaskName, container), isFalse);
    });

    test('a name this build does not know is not retried', () async {
      // A schedule left behind by an older version. `false` would ask the
      // platform to try a name that is never going to start working.
      expect(await runBackgroundTask('peyk.something.old', container), isTrue);
    });
  });
}

/// A facade whose drain always reports a store failure.
final class _RefusingSync implements SyncFacade {
  @override
  Future<Result<SyncStatus, SyncFailure>> drain() async =>
      const Failed(OutboxUnavailable(detail: 'the database is locked'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
