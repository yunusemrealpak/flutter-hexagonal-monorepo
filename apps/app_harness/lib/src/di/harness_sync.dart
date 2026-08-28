import 'package:core_ports/core_ports.dart';
import 'package:injectable/injectable.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_application/sync_application.dart';
import 'package:sync_testing/sync_testing.dart';

/// sync, on fakes.
///
/// **Scenario 3 lives in what this file does not import.** There is no
/// `delivery_api` here, no `payments_api`, nothing of any feature. sync
/// carries every feature's writes and knows none of them; the arrow points the
/// other way, from each feature to `sync_api`, which is the inversion the
/// scenario is named for.
///
/// The proof is mechanical rather than rhetorical: this module registers
/// `SyncFacade`, and `HarnessDelivery` and `HarnessPayments` are the modules
/// that ask for it.
@module
abstract class HarnessSync {
  /// The outbox, in a list.
  ///
  /// Scenario 5, third row: `app_courier` binds `DriftOutboxStore` over a real
  /// SQLite file. The use cases are the same package in both.
  @lazySingleton
  InMemoryOutboxStore get fakeOutbox => InMemoryOutboxStore();

  /// The same instance, as the port.
  @lazySingleton
  OutboxStore outbox(InMemoryOutboxStore fake) => fake;

  /// A transport that accepts everything until a test says otherwise.
  @lazySingleton
  FakeCommandTransport get fakeTransport => FakeCommandTransport();

  /// The same instance, as the port.
  @lazySingleton
  CommandTransportPort commandTransport(FakeCommandTransport fake) => fake;

  /// A server whose clock agrees with this device's.
  @lazySingleton
  ClockSkewPort get skew => FakeClockSkew();

  /// Putting a write in the queue.
  @lazySingleton
  EnqueueCommand enqueue(
    OutboxStore store,
    Clock clock,
    IdGenerator ids,
    Logger logger,
  ) => EnqueueCommand(store: store, clock: clock, ids: ids, logger: logger);

  /// What the badge shows.
  @lazySingleton
  ReadSyncStatus status(
    OutboxStore store,
    NetworkStatus network,
    Clock clock,
  ) => ReadSyncStatus(store: store, network: network, clock: clock);

  /// Sending the queue, with the retry schedule the port describes.
  @lazySingleton
  DrainOutbox drain(
    OutboxStore store,
    CommandTransportPort transport,
    ClockSkewPort skew,
    Clock clock,
    RandomSource random,
    NetworkStatus network,
    Logger logger,
    ReadSyncStatus status,
  ) => DrainOutbox(
    store: store,
    transport: transport,
    skew: skew,
    clock: clock,
    random: random,
    network: network,
    logger: logger,
    status: status,
  );

  /// Reading what the queue gave up on.
  @lazySingleton
  LoadReviewQueue reviewQueue(OutboxStore store) =>
      LoadReviewQueue(store: store);

  /// Deciding what happens to a stuck write.
  @lazySingleton
  ResolveBlockedEntry resolveBlocked(OutboxStore store, Logger logger) =>
      ResolveBlockedEntry(store: store, logger: logger);

  /// The one implementation of `SyncFacade`.
  @lazySingleton
  SyncFacade sync(
    EnqueueCommand enqueue,
    DrainOutbox drain,
    ReadSyncStatus status,
    LoadReviewQueue queue,
    ResolveBlockedEntry resolve,
  ) => SyncCoordinator(
    enqueue: enqueue,
    drain: drain,
    readStatus: status,
    loadReviewQueue: queue,
    resolve: resolve,
  );
}
