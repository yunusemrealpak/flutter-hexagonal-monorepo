@Tags(['widget'])
library;

import 'package:app_harness/main.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_api/sync_api.dart';

void main() {
  // The orchestrator listens for a foreground transition, and
  // AppLifecycleListener asks for the widgets binding. These are plain tests
  // rather than widget tests — there is nothing to pump — so the binding has
  // to be asked for by name.
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNetworkStatus network;
  late _Sync sync;
  late SyncOrchestrator orchestrator;

  SyncOrchestrator build() {
    final built = SyncOrchestrator(
      sync: sync,
      network: network,
      logger: RecordingLogger(),
    );
    addTearDown(built.dispose);
    return built;
  }

  setUp(() => sync = _Sync());

  test('drains once at start when there is already a connection', () async {
    network = FakeNetworkStatus();
    orchestrator = build()..start();
    await pumpEventQueue();

    expect(sync.drains, 1);
  });

  test('does not drain at start in a basement', () async {
    network = FakeNetworkStatus(NetworkCondition.offline);
    orchestrator = build()..start();
    await pumpEventQueue();

    expect(sync.drains, isZero);
  });

  // The case a courier cares about: the writes went into the queue in a
  // basement, and the van reaches the street.
  test('drains when the network comes back', () async {
    network = FakeNetworkStatus(NetworkCondition.offline);
    orchestrator = build()..start();
    await pumpEventQueue();

    network.set(NetworkCondition.metered);
    await pumpEventQueue();

    expect(sync.drains, 1);
  });

  // Wifi that reports itself twice is not a courier walking out of a
  // basement. Only a move *into* a usable connection is a reason to try.
  test('a repeated usable condition is not a transition', () async {
    network = FakeNetworkStatus();
    orchestrator = build()..start();
    await pumpEventQueue();

    network
      ..set(NetworkCondition.unmetered)
      ..set(NetworkCondition.metered);
    await pumpEventQueue();

    expect(sync.drains, 1);
  });

  test('a drain that is already running is not started twice', () async {
    network = FakeNetworkStatus(NetworkCondition.offline);
    sync.hold = true;
    orchestrator = build()..start();

    network.set(NetworkCondition.unmetered);
    await pumpEventQueue();
    await orchestrator.drainNow();

    expect(sync.drains, 1);
  });

  // A failed drain leaves the entries queued and the next connection tries
  // again. What must not happen is the orchestrator refusing to try again
  // because the last attempt threw its latch away.
  test('a refused drain does not block the next one', () async {
    network = FakeNetworkStatus();
    sync.answer = const Failed(SyncOffline());
    orchestrator = build();

    await orchestrator.drainNow();
    await orchestrator.drainNow();

    expect(sync.drains, 2);
  });

  test('stops draining once disposed', () async {
    network = FakeNetworkStatus(NetworkCondition.offline);
    orchestrator = build()..start();
    await orchestrator.dispose();

    network.set(NetworkCondition.unmetered);
    await pumpEventQueue();

    expect(sync.drains, isZero);
  });
}

/// A `SyncFacade` that counts drains and can be held open.
///
/// A fake rather than a mock: the orchestrator's whole job is *when* to call
/// drain, so what a test needs is a real count and a real future to hold, not
/// a script of expected calls.
final class _Sync implements SyncFacade {
  int drains = 0;
  bool hold = false;
  Result<SyncStatus, SyncFailure> answer = const Success(SyncStatus.idle());

  @override
  Future<Result<SyncStatus, SyncFailure>> drain() async {
    drains++;
    if (hold) await Future<void>.delayed(const Duration(milliseconds: 50));
    return answer;
  }

  @override
  Future<Result<OutboxEntry, SyncFailure>> enqueue(
    SyncCommand command, {
    ConflictPolicy policy = const ConflictPolicy.lastWriteWins(),
  }) => throw UnimplementedError('the orchestrator never enqueues');

  @override
  Future<Result<List<OutboxEntry>, SyncFailure>> awaitingReview() =>
      throw UnimplementedError('the orchestrator never reviews');

  @override
  Future<Result<OutboxEntry, SyncFailure>> retry(OutboxEntryId id) =>
      throw UnimplementedError('the orchestrator never retries one entry');

  @override
  Stream<SyncStatus> statusChanges() => const Stream<SyncStatus>.empty();
}
