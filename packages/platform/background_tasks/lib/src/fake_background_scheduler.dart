import 'package:core_kernel/core_kernel.dart';

import 'background_scheduler.dart';
import 'scheduling_failure.dart';
import 'task_constraints.dart';

/// One thing a test asked the scheduler for.
final class ScheduledTask {
  /// Creates the record.
  const ScheduledTask({
    required this.name,
    required this.constraints,
    this.interval,
    this.delay,
  });

  /// What it is called.
  final String name;

  /// What the device has to be doing.
  final TaskConstraints constraints;

  /// How often it repeats, or `null` when it runs once.
  final Duration? interval;

  /// How long before it first runs, or `null` when it repeats.
  final Duration? delay;

  /// Whether this is a repeating task.
  bool get isPeriodic => interval != null;

  @override
  String toString() =>
      'ScheduledTask($name, interval: $interval, delay: $delay, '
      '$constraints)';
}

/// A [BackgroundScheduler] that remembers instead of scheduling.
///
/// It lives beside the contract rather than in `core_testing`, which is the
/// §1.1.1 rule for a technology contract: the fake for a product port belongs
/// with the product, and the fake for a platform belongs with the platform.
///
/// It records rather than pretending to run anything. Nothing in this
/// workspace can run a background task in a test — that needs an operating
/// system — so the assertable behaviour is *what was asked for*, and a fake
/// that invented a wake-up would be asserting against a story rather than
/// against the platform.
final class FakeBackgroundScheduler implements BackgroundScheduler {
  /// Every task asked for, in order, with replacements applied.
  final List<ScheduledTask> tasks = [];

  /// Every name that was cancelled.
  final List<String> cancelled = [];

  /// How many times everything was cancelled at once.
  int cancelledAll = 0;

  /// What the next call answers, if a test wants a refusal.
  SchedulingFailure? nextFailure;

  @override
  Future<Result<void, SchedulingFailure>> schedulePeriodic({
    required String name,
    required Duration interval,
    TaskConstraints constraints = const TaskConstraints(),
  }) async => _record(
    ScheduledTask(
      name: name,
      constraints: constraints,
      interval: interval < BackgroundScheduler.minimumInterval
          ? BackgroundScheduler.minimumInterval
          : interval,
    ),
  );

  @override
  Future<Result<void, SchedulingFailure>> scheduleOnce({
    required String name,
    Duration delay = Duration.zero,
    TaskConstraints constraints = const TaskConstraints(),
  }) async => _record(
    ScheduledTask(name: name, constraints: constraints, delay: delay),
  );

  @override
  Future<Result<void, SchedulingFailure>> cancel(String name) async {
    final failure = _take();
    if (failure != null) return Failed(failure);
    cancelled.add(name);
    tasks.removeWhere((task) => task.name == name);
    return const Success(null);
  }

  @override
  Future<Result<void, SchedulingFailure>> cancelAll() async {
    final failure = _take();
    if (failure != null) return Failed(failure);
    cancelledAll++;
    tasks.clear();
    return const Success(null);
  }

  /// The task scheduled under [name], or `null`.
  ScheduledTask? taskNamed(String name) {
    for (final task in tasks) {
      if (task.name == name) return task;
    }
    return null;
  }

  Result<void, SchedulingFailure> _record(ScheduledTask task) {
    final failure = _take();
    if (failure != null) return Failed(failure);
    // Replacing rather than appending, because that is what the contract
    // promises: an app that schedules on every launch must not end up with a
    // list that grows, and a fake that let it would hide the bug.
    tasks
      ..removeWhere((existing) => existing.name == task.name)
      ..add(task);
    return const Success(null);
  }

  SchedulingFailure? _take() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }
}
