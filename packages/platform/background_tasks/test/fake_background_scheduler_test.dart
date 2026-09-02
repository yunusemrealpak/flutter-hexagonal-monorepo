import 'package:background_tasks/background_tasks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scheduling the same name twice replaces rather than appends', () {
    // The contract an app relies on when it schedules on every launch. A fake
    // that appended would let a growing list of duplicates pass a test.
    final scheduler = FakeBackgroundScheduler();

    return Future(() async {
      await scheduler.schedulePeriodic(
        name: 'peyk.sync.drain',
        interval: const Duration(hours: 1),
      );
      await scheduler.schedulePeriodic(
        name: 'peyk.sync.drain',
        interval: const Duration(hours: 6),
      );

      expect(scheduler.tasks, hasLength(1));
      expect(
        scheduler.taskNamed('peyk.sync.drain')!.interval,
        const Duration(hours: 6),
      );
    });
  });

  test('it applies the same floor the adapter does', () async {
    // A fake that accepted five minutes would let a test assert a period no
    // device will ever honour.
    final scheduler = FakeBackgroundScheduler();

    await scheduler.schedulePeriodic(
      name: 'peyk.sync.drain',
      interval: const Duration(minutes: 5),
    );

    expect(
      scheduler.taskNamed('peyk.sync.drain')!.interval,
      BackgroundScheduler.minimumInterval,
    );
  });

  test('a queued failure is answered once', () async {
    final scheduler = FakeBackgroundScheduler()
      ..nextFailure = const SchedulingUnavailable(detail: 'no scheduler');

    final refused = await scheduler.scheduleOnce(name: 'peyk.sync.drain.now');
    final allowed = await scheduler.scheduleOnce(name: 'peyk.sync.drain.now');

    expect(refused.isFailure, isTrue);
    expect(allowed.isSuccess, isTrue);
    expect(scheduler.tasks, hasLength(1));
  });

  test('cancelling forgets the task', () async {
    final scheduler = FakeBackgroundScheduler();
    await scheduler.schedulePeriodic(
      name: 'peyk.sync.drain',
      interval: const Duration(hours: 1),
    );

    await scheduler.cancel('peyk.sync.drain');

    expect(scheduler.cancelled, ['peyk.sync.drain']);
    expect(scheduler.taskNamed('peyk.sync.drain'), isNull);
  });
}
