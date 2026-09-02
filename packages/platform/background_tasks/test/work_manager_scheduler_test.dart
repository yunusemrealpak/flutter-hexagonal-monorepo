import 'package:background_tasks/background_tasks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workmanager_platform_interface/workmanager_platform_interface.dart';

/// One call the adapter made.
typedef _Call = ({
  String unique,
  Duration? frequency,
  Duration? delay,
  Constraints? constraints,
});

/// A `WorkmanagerPlatform` that records instead of scheduling.
///
/// It extends rather than implements, which is what the platform interface
/// asks for and what makes this survive the plugin adding a method.
final class _Platform extends WorkmanagerPlatform {
  _Platform() : super();

  final List<_Call> periodic = [];
  final List<_Call> once = [];
  final List<String> cancelled = [];
  int cancelledAll = 0;

  /// What the next call throws, if a test wants a refusal.
  ///
  /// An `Exception` rather than an `Object`, so that rethrowing it does not
  /// trip `only_throw_errors` — and the three things this adapter has to
  /// survive are all exceptions anyway.
  Exception? nextError;

  void _maybeThrow() {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
  }

  @override
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? flexInterval,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingPeriodicWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async {
    _maybeThrow();
    policies.add(existingWorkPolicy);
    periodic.add((
      unique: uniqueName,
      frequency: frequency,
      delay: initialDelay,
      constraints: constraints,
    ));
  }

  final List<ExistingPeriodicWorkPolicy?> policies = [];

  @override
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    OutOfQuotaPolicy? outOfQuotaPolicy,
    ForegroundServiceConfig? foregroundServiceConfig,
    bool expedited = false,
  }) async {
    _maybeThrow();
    once.add((
      unique: uniqueName,
      frequency: null,
      delay: initialDelay,
      constraints: constraints,
    ));
  }

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {
    _maybeThrow();
    cancelled.add(uniqueName);
  }

  @override
  Future<void> cancelAll() async {
    _maybeThrow();
    cancelledAll++;
  }
}

void main() {
  late _Platform platform;
  late WorkManagerScheduler scheduler;

  setUp(() {
    platform = _Platform();
    scheduler = WorkManagerScheduler(platform);
  });

  group('schedulePeriodic', () {
    test('passes the period through when it is long enough', () async {
      final scheduled = await scheduler.schedulePeriodic(
        name: 'peyk.sync.drain',
        interval: const Duration(hours: 1),
      );

      expect(scheduled.isSuccess, isTrue);
      expect(platform.periodic.single.unique, 'peyk.sync.drain');
      expect(platform.periodic.single.frequency, const Duration(hours: 1));
    });

    test('raises a period the platform would silently clamp', () async {
      // WorkManager's floor is fifteen minutes and it applies it without
      // telling anybody. An app that asked for five and believed it had five
      // would build a policy on a number that was never true.
      await scheduler.schedulePeriodic(
        name: 'peyk.sync.drain',
        interval: const Duration(minutes: 5),
      );

      expect(
        platform.periodic.single.frequency,
        BackgroundScheduler.minimumInterval,
      );
    });

    test('updates an existing schedule rather than keeping it', () async {
      // `keep` would leave the period the first install asked for in force
      // forever: a shipped change to the interval would never take effect on
      // a device that had run the old build.
      await scheduler.schedulePeriodic(
        name: 'peyk.sync.drain',
        interval: const Duration(hours: 1),
      );

      expect(platform.policies.single, ExistingPeriodicWorkPolicy.update);
    });

    test('translates the constraints it was given', () async {
      await scheduler.schedulePeriodic(
        name: 'peyk.sync.drain',
        interval: const Duration(hours: 1),
        constraints: const TaskConstraints(
          networkRequired: true,
          batteryNotLow: true,
        ),
      );

      final constraints = platform.periodic.single.constraints!;
      expect(constraints.networkType, NetworkType.connected);
      expect(constraints.requiresBatteryNotLow, isTrue);
      expect(constraints.requiresCharging, isFalse);
    });

    test('asks for no network when nothing asked for one', () async {
      // `notRequired` rather than leaving it null: WorkManager's own default
      // is not required, and saying so is what makes the translation total.
      await scheduler.schedulePeriodic(
        name: 'peyk.sync.drain',
        interval: const Duration(hours: 1),
      );

      expect(
        platform.periodic.single.constraints!.networkType,
        NetworkType.notRequired,
      );
    });
  });

  group('scheduleOnce', () {
    test('carries the delay', () async {
      await scheduler.scheduleOnce(
        name: 'peyk.sync.drain.now',
        delay: const Duration(minutes: 2),
      );

      expect(platform.once.single.delay, const Duration(minutes: 2));
    });

    test('is not raised to the periodic floor', () async {
      // The floor is a property of *repeating* work. A one-off in two minutes
      // is something both platforms will honour, and clamping it would be
      // this adapter inventing a restriction.
      await scheduler.scheduleOnce(
        name: 'peyk.sync.drain.now',
        delay: const Duration(seconds: 30),
      );

      expect(platform.once.single.delay, const Duration(seconds: 30));
    });
  });

  group('cancelling', () {
    test('withdraws one name', () async {
      await scheduler.cancel('peyk.sync.drain');

      expect(platform.cancelled, ['peyk.sync.drain']);
    });

    test('withdraws everything', () async {
      await scheduler.cancelAll();

      expect(platform.cancelledAll, 1);
    });
  });

  group('nothing crosses the boundary as an exception', () {
    test('a refusal keeps the platform code', () async {
      // The iOS case this is written for: background refresh switched off, or
      // an identifier the app never declared in its plist. Mapping those into
      // one product word here would be this package deciding what they mean.
      platform.nextError = PlatformException(
        code: 'BGTaskSchedulerErrorDomainNotPermitted',
        message: 'background refresh is off',
      );

      final scheduled = await scheduler.schedulePeriodic(
        name: 'peyk.sync.drain',
        interval: const Duration(hours: 1),
      );

      expect(
        scheduled.fold((_) => null, (failure) => failure),
        isA<SchedulingRefused>().having(
          (f) => f.code,
          'code',
          'BGTaskSchedulerErrorDomainNotPermitted',
        ),
      );
    });

    test('a platform with no implementation is unavailable, not a crash', () {
      // What web and desktop produce. A `Result` rather than a throw is the
      // whole of rule 1.2.9 at the only boundary that can produce this.
      platform.nextError = MissingPluginException('no implementation');

      expect(
        scheduler.cancelAll().then((r) => r.fold((_) => null, (f) => f)),
        completion(isA<SchedulingUnavailable>()),
      );
    });

    test('and so is anything else the plugin throws', () async {
      platform.nextError = const FormatException('frequency is negative');

      final scheduled = await scheduler.scheduleOnce(name: 'x');

      expect(
        scheduled.fold((_) => null, (failure) => failure),
        isA<SchedulingUnavailable>(),
      );
    });
  });
}
