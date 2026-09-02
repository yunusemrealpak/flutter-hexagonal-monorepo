import 'package:core_kernel/core_kernel.dart';

import 'scheduling_failure.dart';
import 'task_constraints.dart';

/// Asks the operating system to run work while the app is not running.
///
/// A technology contract, like `HttpTransport` in `http_dio` and
/// `LocationSource` in `location_service`, and declared here for the reason
/// §1.1.1 gives: nothing in the product asks for "a periodic task". `sync`
/// asks for its outbox to be drained; *when a device is willing to wake up* is
/// a question only Android's WorkManager and iOS's BGTaskScheduler can answer,
/// and an app is the only layer that knows both.
///
/// **A task is a name, not a function.** Everything here schedules; nothing
/// here runs. The work happens in a second isolate that the operating system
/// starts long after this call returned, with a fresh Dart heap and no
/// container, so a closure could not survive the trip. The app registers one
/// entry point, this schedules names, and the entry point decides what each
/// name means — which is also why [schedulePeriodic] takes a `String` a
/// composition root chose rather than an enum this package invented.
///
/// Every method returns a `Result`: an operating system can refuse, and rule
/// 1.2.9 does not let that arrive as an exception.
abstract interface class BackgroundScheduler {
  /// The shortest period either platform will honour.
  ///
  /// Android's WorkManager floor, and iOS is looser than a floor — it decides
  /// when a device is idle enough and may not run a task for days. Anything
  /// shorter is raised to this by an adapter rather than passed on, so that a
  /// caller is never told a period the platform quietly replaced.
  static const Duration minimumInterval = Duration(minutes: 15);

  /// Asks for [name] to be run about every [interval].
  ///
  /// *About*. Both platforms batch wake-ups to save power, so the period is a
  /// floor and a hint rather than a schedule. Work whose correctness depends
  /// on running at a particular time does not belong here.
  ///
  /// Scheduling a name that is already scheduled replaces it rather than
  /// adding a second, which is what lets an app call this on every launch.
  Future<Result<void, SchedulingFailure>> schedulePeriodic({
    required String name,
    required Duration interval,
    TaskConstraints constraints = const TaskConstraints(),
  });

  /// Asks for [name] to be run once, no sooner than [delay] from now.
  Future<Result<void, SchedulingFailure>> scheduleOnce({
    required String name,
    Duration delay = Duration.zero,
    TaskConstraints constraints = const TaskConstraints(),
  });

  /// Withdraws [name].
  ///
  /// Cancelling something that was never scheduled succeeds: a caller signing
  /// somebody out has no way to know whether the schedule survived the last
  /// install, and refusing would make it handle a failure it cannot act on.
  Future<Result<void, SchedulingFailure>> cancel(String name);

  /// Withdraws everything this app scheduled.
  Future<Result<void, SchedulingFailure>> cancelAll();
}
