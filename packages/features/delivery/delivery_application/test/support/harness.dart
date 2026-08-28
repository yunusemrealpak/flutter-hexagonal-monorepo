import 'package:core_testing/core_testing.dart';
import 'package:delivery_application/delivery_application.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:sync_testing/sync_testing.dart';

/// Everything a delivery use case needs, all of it fake.
///
/// Assembled here rather than in each test's `setUp`, because the interesting
/// part of these tests is the *order* the use cases do things in, and a
/// twenty-line arrangement in front of every one of them buries it.
///
/// Every collaborator is a port implementation, which is what a composition
/// root supplies in an app. That the harness looks like a small
/// `app_harness` is not a coincidence: it is the same wiring with different
/// adapters, which is scenario 5 seen from the test suite.
final class Harness {
  /// Builds the harness with a fixed clock and a counting id generator.
  Harness()
    : clock = FakeClock(DeliveryFixtures.noon),
      ids = FakeIdGenerator('attempt');

  /// The device's position, as far as delivery is concerned.
  final FakeGeoFence fence = FakeGeoFence();

  /// Where the evidence goes.
  final FakeProofStore store = FakeProofStore();

  /// What shrinks a photograph.
  final FakeMediaCompressor compressor = FakeMediaCompressor();

  /// The operation's record of what happened at the door.
  final FakeDeliveryGateway gateway = FakeDeliveryGateway();

  /// The outbox every write goes through.
  final FakeSyncFacade queue = FakeSyncFacade();

  /// The bus `DeliveryCompleted` is published on.
  final RecordingEventBus events = RecordingEventBus();

  /// Time, which only moves when a test moves it.
  final FakeClock clock;

  /// Identifiers, which count rather than being random.
  final FakeIdGenerator ids;

  /// How big a queued photograph may be, for the tests that care.
  int photoLimitBytes = 512 * 1024;

  /// The use case that opens an attempt.
  StartAttempt get start => StartAttempt(fence: fence, clock: clock, ids: ids);

  /// The use case that closes one with evidence.
  CompleteWithProof get complete => CompleteWithProof(
    store: store,
    compressor: compressor,
    sync: queue,
    events: events,
    clock: clock,
    photoLimitBytes: photoLimitBytes,
  );

  /// The use case that closes one without.
  FailWithReason get fail => FailWithReason(sync: queue, clock: clock);

  /// The read side.
  AttemptReads get reads => AttemptReads(gateway: gateway);

  /// The one stream the three coordinators announce on.
  late final DeliveryChannel channel = DeliveryChannel();

  /// Arriving, wired the way a courier's composition root would wire it.
  DeliveryExecutionCoordinator get execution =>
      DeliveryExecutionCoordinator(startAttempt: start, channel: channel);

  /// Closing an attempt — which both apps compose.
  DeliverySettlementCoordinator get settlement => DeliverySettlementCoordinator(
    complete: complete,
    fail: fail,
    channel: channel,
  );

  /// Reading attempts back.
  DeliveryHistoryCoordinator get history =>
      DeliveryHistoryCoordinator(reads: reads, channel: channel);

  /// Releases what the harness holds open.
  Future<void> dispose() async {
    await channel.dispose();
    await queue.dispose();
    await events.dispose();
  }
}
