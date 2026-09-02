import 'package:core_kernel/core_kernel.dart';
import 'package:flutter/services.dart';
import 'package:workmanager_platform_interface/workmanager_platform_interface.dart';

import 'background_scheduler.dart';
import 'scheduling_failure.dart';
import 'task_constraints.dart';

/// A [BackgroundScheduler] over Android's WorkManager and iOS's
/// BGTaskScheduler.
///
/// It takes the plugin's *platform interface* rather than the plugin's own
/// singleton, which is the decision every adapter in `platform/` makes and the
/// reason `testPlatform()` in each app can stand the whole product up with no
/// device. It is also rule 1.2.7: a package reaching for `Workmanager()` would
/// be a package with a global in it.
///
/// **This adapter schedules and never runs.** Registering the entry point that
/// the operating system calls back into is an app's job — it is a top-level
/// function with a `@pragma('vm:entry-point')` on it, and the app is what owns
/// both the pragma and the container the work needs. See this package's README
/// for what that costs and what it means here.
final class WorkManagerScheduler implements BackgroundScheduler {
  /// Creates the adapter over the plugin's platform interface.
  const WorkManagerScheduler(this._platform);

  final WorkmanagerPlatform _platform;

  @override
  Future<Result<void, SchedulingFailure>> schedulePeriodic({
    required String name,
    required Duration interval,
    TaskConstraints constraints = const TaskConstraints(),
  }) => _guard(
    () => _platform.registerPeriodicTask(
      name,
      name,
      // Raised rather than passed on. WorkManager clamps anything below its
      // own floor without telling anybody, so an app asking for five minutes
      // would get fifteen and believe it had five. Doing it here means the
      // number that reaches the platform is the number this adapter can
      // defend, and a caller reading `minimumInterval` learns the truth.
      frequency: interval < BackgroundScheduler.minimumInterval
          ? BackgroundScheduler.minimumInterval
          : interval,
      constraints: _translate(constraints),
      // `update` rather than `keep`. An app schedules on every launch, and
      // `keep` would leave the period the *first* install asked for in force
      // forever — a change to the interval would ship and never take effect on
      // any device that had run the old build.
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    ),
  );

  @override
  Future<Result<void, SchedulingFailure>> scheduleOnce({
    required String name,
    Duration delay = Duration.zero,
    TaskConstraints constraints = const TaskConstraints(),
  }) => _guard(
    () => _platform.registerOneOffTask(
      name,
      name,
      initialDelay: delay,
      constraints: _translate(constraints),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    ),
  );

  @override
  Future<Result<void, SchedulingFailure>> cancel(String name) =>
      _guard(() => _platform.cancelByUniqueName(name));

  @override
  Future<Result<void, SchedulingFailure>> cancelAll() =>
      _guard(_platform.cancelAll);

  /// Runs [call] and turns everything it can throw into a failure.
  ///
  /// The catch-all is the point of the adapter boundary: a plugin can throw a
  /// `PlatformException`, a `MissingPluginException` on a platform that
  /// registered nothing, or a plain error from its own argument checking, and
  /// rule 1.2.9 says none of those may cross this contract.
  Future<Result<void, SchedulingFailure>> _guard(
    Future<void> Function() call,
  ) async {
    try {
      await call();
      return const Success(null);
    } on PlatformException catch (error) {
      // The platform's own code, unmapped. iOS distinguishes background
      // refresh being switched off from an identifier the app never declared,
      // and those are different things to whoever reads the log.
      return Failed(
        SchedulingRefused(code: error.code, detail: error.message),
      );
    } on MissingPluginException catch (error) {
      return Failed(SchedulingUnavailable(detail: '$error'));
    } on Object catch (error) {
      return Failed(SchedulingUnavailable(detail: '$error'));
    }
  }

  Constraints _translate(TaskConstraints constraints) => Constraints(
    networkType: constraints.networkRequired
        ? NetworkType.connected
        : NetworkType.notRequired,
    requiresCharging: constraints.chargingRequired,
    requiresBatteryNotLow: constraints.batteryNotLow,
  );
}
