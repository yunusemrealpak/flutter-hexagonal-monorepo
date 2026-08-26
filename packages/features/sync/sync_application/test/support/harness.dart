import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:core_testing/core_testing.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_application/sync_application.dart';
import 'package:sync_testing/sync_testing.dart';

/// Everything a sync use case needs, wired to fakes a test can steer.
///
/// The whole point of the constructor-injection rule is visible here: standing
/// the drain up takes seven fakes and no framework, no container, and no
/// network. Every one of them is a port the composition root would answer with
/// something real.
final class Harness {
  /// Builds the fakes and the use cases over them.
  Harness({
    this.schedule = RetrySchedule.standard,
    this.batchSize = 50,
    List<double> jitter = const [0.5],
    NetworkCondition connection = NetworkCondition.unmetered,
  }) : clock = FakeClock(noon),
       random = FakeRandomSource(jitter),
       network = FakeNetworkStatus(connection);

  /// A fixed instant every test in this package measures from.
  static final DateTime noon = DateTime.utc(2026, 3, 14, 12);

  /// The outbox under test.
  final InMemoryOutboxStore store = InMemoryOutboxStore();

  /// The server, as far as the drain is concerned.
  final FakeCommandTransport transport = FakeCommandTransport();

  /// How far the device's clock is from the server's.
  final FakeClockSkew skew = FakeClockSkew();

  /// Time, which only moves when a test moves it.
  final FakeClock clock;

  /// Identifiers, in a sequence a test can predict.
  final FakeIdGenerator ids = FakeIdGenerator('entry');

  /// The jitter draws, in the order the drain will take them.
  final FakeRandomSource random;

  /// Whether the device believes it can reach anything.
  final FakeNetworkStatus network;

  /// What the use cases wrote down.
  final RecordingLogger logger = RecordingLogger();

  /// The schedule the drain runs under.
  final RetrySchedule schedule;

  /// How many entries one drain works through.
  final int batchSize;

  late final ReadSyncStatus readStatus = ReadSyncStatus(
    store: store,
    network: network,
    clock: clock,
    batchSize: batchSize,
  );

  /// The use case under test in `enqueue_command_test.dart`.
  late final EnqueueCommand enqueue = EnqueueCommand(
    store: store,
    clock: clock,
    ids: ids,
    logger: logger,
  );

  /// The use case under test in `drain_outbox_test.dart`.
  late final DrainOutbox drain = DrainOutbox(
    store: store,
    transport: transport,
    skew: skew,
    clock: clock,
    random: random,
    network: network,
    logger: logger,
    status: readStatus,
    schedule: schedule,
    batchSize: batchSize,
  );

  /// Reads the work the queue gave up on.
  late final LoadReviewQueue reviewQueue = LoadReviewQueue(store: store);

  /// Puts blocked work back in the queue.
  late final ResolveBlockedEntry resolve = ResolveBlockedEntry(
    store: store,
    logger: logger,
  );

  /// The driving port, over the same use cases.
  late final SyncCoordinator coordinator = SyncCoordinator(
    enqueue: enqueue,
    drain: drain,
    readStatus: readStatus,
    loadReviewQueue: reviewQueue,
    resolve: resolve,
  );

  /// Puts an entry straight into the store, bypassing the use case.
  Future<OutboxEntry> seed(OutboxEntry entry) async {
    await store.put(entry);
    return entry;
  }

  /// The entries the store currently holds that are not blocked.
  Future<List<OutboxEntry>> pending() async => (await store.pending()).fold(
    (rows) => rows,
    (f) => throw StateError('$f'),
  );

  /// The entries a person has to look at.
  Future<List<OutboxEntry>> blocked() async => (await store.blocked()).fold(
    (rows) => rows,
    (f) => throw StateError('$f'),
  );
}

/// Unwraps a [Result] where a failure means the test setup is wrong.
T unwrap<T, F>(Result<T, F> result) =>
    result.fold((value) => value, (failure) => throw StateError('$failure'));
