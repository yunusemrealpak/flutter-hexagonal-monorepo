import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_application/delivery_application.dart';
import 'package:delivery_testing/delivery_testing.dart';
import 'package:injectable/injectable.dart';
import 'package:sync_api/sync_api.dart';

/// delivery, on fakes.
///
/// Two scenarios cross here. Scenario 3: `CompleteWithProof` takes a
/// `SyncFacade`, so a hand-over recorded in a basement goes into sync's queue
/// and sync never learns what a delivery is. Scenario 2: the same use case
/// publishes `DeliveryCompleted` on the event bus, and `payments` — which this
/// module does not import — is listening.
@module
abstract class HarnessDelivery {
  /// The evidence store this app binds.
  ///
  /// Scenario 5, fourth row: `app_courier` binds `LocalEncryptedProofStore`
  /// over a key-value store on the device, `app_dispatcher` binds
  /// `RemoteProofStore` over HTTP. A dispatcher's browser has no proof to keep.
  @lazySingleton
  FakeProofStore get fakeProofs => FakeProofStore();

  /// The same instance, as the port.
  @lazySingleton
  ProofStorePort proofs(FakeProofStore fake) => fake;

  /// A fence that says the courier is where they say they are.
  @lazySingleton
  FakeGeoFence get fakeFence => FakeGeoFence();

  /// The same instance, as the port.
  @lazySingleton
  GeoFencePort fence(FakeGeoFence fake) => fake;

  /// A compressor that hands back what it was given.
  @lazySingleton
  MediaCompressorPort get compressor => FakeMediaCompressor();

  /// The operation's attempts.
  @lazySingleton
  FakeDeliveryGateway get fakeGateway => FakeDeliveryGateway();

  /// The same instance, as the port.
  @lazySingleton
  DeliveryGateway gateway(FakeDeliveryGateway fake) => fake;

  /// Arriving at a door.
  @lazySingleton
  StartAttempt start(GeoFencePort fence, Clock clock, IdGenerator ids) =>
      StartAttempt(fence: fence, clock: clock, ids: ids);

  /// Handing it over.
  @lazySingleton
  CompleteWithProof complete(
    ProofStorePort store,
    MediaCompressorPort compressor,
    SyncFacade sync,
    DomainEventBus events,
    Clock clock,
  ) => CompleteWithProof(
    store: store,
    compressor: compressor,
    sync: sync,
    events: events,
    clock: clock,
  );

  /// Recording that it did not happen.
  @lazySingleton
  FailWithReason fail(SyncFacade sync, Clock clock) =>
      FailWithReason(sync: sync, clock: clock);

  /// Reading an attempt back.
  @lazySingleton
  AttemptReads reads(DeliveryGateway gateway) => AttemptReads(gateway: gateway);

  /// The one stream the three coordinators announce on.
  @lazySingleton
  DeliveryChannel get deliveryChannel => DeliveryChannel();

  /// Arriving at a door.
  @lazySingleton
  DeliveryExecution execution(StartAttempt start, DeliveryChannel channel) =>
      DeliveryExecutionCoordinator(startAttempt: start, channel: channel);

  /// Closing an attempt.
  @lazySingleton
  DeliverySettlement settlement(
    CompleteWithProof complete,
    FailWithReason fail,
    DeliveryChannel channel,
  ) => DeliverySettlementCoordinator(
    complete: complete,
    fail: fail,
    channel: channel,
  );

  /// Reading attempts back.
  ///
  /// **All three are bound here, and only here.** This app composes every
  /// feature, so it is the one place delivery's whole driving surface is put
  /// together.
  @lazySingleton
  DeliveryHistory history(AttemptReads reads, DeliveryChannel channel) =>
      DeliveryHistoryCoordinator(reads: reads, channel: channel);
}
