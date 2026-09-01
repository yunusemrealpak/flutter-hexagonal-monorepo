import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_application/delivery_application.dart';
import 'package:delivery_infrastructure/delivery_infrastructure.dart';
import 'package:http_dio/http_dio.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_application/identity_application.dart';
import 'package:identity_infrastructure/identity_infrastructure.dart';
import 'package:injectable/injectable.dart';
import 'package:location_service/location_service.dart';
import 'package:payments_api/payments_api.dart';
import 'package:payments_application/payments_application.dart';
import 'package:payments_infrastructure/payments_infrastructure.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_application/routing_application.dart';
import 'package:routing_infrastructure/routing_infrastructure.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_application/shipments_application.dart';
import 'package:shipments_infrastructure/shipments_infrastructure.dart';
import 'package:storage_drift/storage_drift.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_application/sync_application.dart';
import 'package:sync_infrastructure/sync_infrastructure.dart';

import 'courier_platform.dart';

/// The six full-split features, on the adapters a phone in a van needs.
///
/// **This file is one column of the table in §5.5 of the specification.**
/// Every `_application` package below is byte-for-byte the one `app_harness`
/// composes and the one `app_dispatcher` composes. What differs is five
/// bindings, and they are marked.
///
/// One module for six features rather than six modules, because the
/// interesting thing about this file is the *comparison* — the rows read as a
/// table when they are next to each other and as six unrelated files when
/// they are not.
@module
abstract class CourierFeatures {
  // -- identity ------------------------------------------------------------

  /// **Scenario 5, row 2.** A courier signs in on a device the operation has
  /// registered, so the credentials are bound to it: a stolen password is
  /// worth nothing without the handset. `app_dispatcher` binds
  /// `SsoCredentialGateway` instead, because a dispatcher signs in at whatever
  /// desk they are at.
  @lazySingleton
  CredentialGateway gateway(HttpTransport transport) =>
      DeviceBoundCredentialGateway(transport: transport);

  /// The session, in the keychain.
  @lazySingleton
  SessionStore sessions(SecureStore store) => SecureSessionStore(store: store);

  /// This installation's registration.
  ///
  /// The fingerprint is the app's to supply — `identity_infrastructure` says
  /// so in the field's doc comment — because what identifies a device is a
  /// product decision rather than an adapter's. A real one would digest the
  /// model, the OS build and an install-time secret.
  @lazySingleton
  DeviceRegistry devices(
    KeyValueStore store,
    IdGenerator ids,
    Clock clock,
  ) => InstallationDeviceRegistry(
    store: store,
    ids: ids,
    clock: clock,
    fingerprint: 'courier-handset',
  );

  /// The coordinator, once, under its own type.
  @lazySingleton
  IdentityCoordinator identity(
    CredentialGateway gateway,
    SessionStore store,
    DeviceRegistry devices,
    Clock clock,
    Logger logger,
  ) => IdentityCoordinator(
    gateway: gateway,
    store: store,
    devices: devices,
    clock: clock,
    logger: logger,
  );

  /// Signing in.
  @lazySingleton
  IdentityFacade identityFacade(IdentityCoordinator it) => it;

  /// Who is signed in.
  @lazySingleton
  SessionReader sessionReader(IdentityCoordinator it) => it;

  /// What they may do.
  @lazySingleton
  PermissionChecker permissionChecker(IdentityCoordinator it) => it;

  /// What the outbound transport presents.
  ///
  /// The fourth view of the same coordinator, and the one that closes the
  /// oldest hole in this workspace: before it existed every gateway but
  /// identity's own sent its requests with no credential at all.
  @lazySingleton
  SessionTokens sessionTokens(IdentityCoordinator it) => it;

  /// The credential the interceptor attaches, out of the session identity
  /// holds.
  ///
  /// Registered here rather than in the ports module because it is identity's
  /// adapter — the ports module binds what `core_ports` declares, and this
  /// answers a contract `platform/http_dio` declares. The interceptor that
  /// consumes it is installed on the `Dio` instance in `main.dart`, after the
  /// container exists, because it needs both this and the client itself.
  @lazySingleton
  AuthorizationProvider authorization(SessionTokens tokens, Logger logger) =>
      BearerAuthorization(tokens: tokens, logger: logger);

  // -- shipments -----------------------------------------------------------

  /// The operation's shipments, over REST.
  @lazySingleton
  ShipmentGateway shipmentGateway(HttpTransport transport) =>
      RestShipmentGateway(transport: transport);

  /// The offline copy, in the device's key-value table.
  ///
  /// This is what "offline-first" means concretely: `FindShipment` asks the
  /// gateway and falls back to this, so a courier in a basement sees the
  /// manifest they were given this morning.
  @lazySingleton
  ShipmentCache shipmentCache(KeyValueStore store) =>
      KeyValueShipmentCache(store: store);

  /// **Two adapters for one port, and this app binds the offline one.**
  ///
  /// `ManifestBarcodeResolver` answers a scan from the cached manifest without
  /// a network — which is the whole point on a phone. `app_dispatcher` binds
  /// `RemoteBarcodeResolver`, because a dispatcher scanning a parcel is
  /// looking for one that may not be on any manifest yet.
  ///
  /// The courier id is a placeholder here for the same reason the fingerprint
  /// is: it belongs to whoever signed in, and a container built before sign-in
  /// cannot know it. A production app would rebuild this scope on sign-in.
  @lazySingleton
  BarcodeResolverPort barcodes(ShipmentCache cache) =>
      ManifestBarcodeResolver(cache: cache, courierId: 'courier-current');

  /// Reading one shipment.
  @lazySingleton
  FindShipment find(ShipmentGateway gateway, ShipmentCache cache) =>
      FindShipment(gateway: gateway, cache: cache);

  /// Turning a scan into a shipment.
  @lazySingleton
  ResolveBarcode resolve(BarcodeResolverPort resolver, FindShipment find) =>
      ResolveBarcode(resolver: resolver, findShipment: find);

  /// The day's list.
  @lazySingleton
  LoadManifest manifest(ShipmentGateway gateway, ShipmentCache cache) =>
      LoadManifest(gateway: gateway, cache: cache);

  /// The state machine. Scenario 1: it reads payments through a contract.
  @lazySingleton
  AdvanceShipment advance(
    ShipmentGateway gateway,
    ShipmentCache cache,
    Clock clock,
    DomainEventBus events,
    Logger logger,
    PaymentStatusReader payments,
  ) => AdvanceShipment(
    gateway: gateway,
    cache: cache,
    clock: clock,
    events: events,
    logger: logger,
    payments: payments,
  );

  /// The one implementation of `ShipmentsFacade`.
  @lazySingleton
  ShipmentsFacade shipments(
    FindShipment find,
    ResolveBarcode resolve,
    LoadManifest manifest,
    AdvanceShipment advance,
  ) => ShipmentsCoordinator(
    findShipment: find,
    resolveBarcode: resolve,
    loadManifest: manifest,
    advanceShipment: advance,
  );

  // -- routing -------------------------------------------------------------

  /// The device's GPS.
  ///
  /// It takes the `PermissionRequester` *port* rather than the plugin, and
  /// that is rule 1.1's platform paragraph in practice: `location_service` may
  /// not depend on `device_permissions`, so it asks for the contract and this
  /// app supplies the adapter. Two platform packages that needed each other,
  /// resolved the way everything else in the workspace is.
  @lazySingleton
  LocationSource locationSource(
    CourierPlatform platform,
    PermissionRequester permissions,
  ) => GeolocatorLocationSource(platform.location, permissions);

  /// **Scenario 5, row 1, and scenario 4's payoff.** The route is ordered on
  /// the phone by a 2-opt heuristic, because a courier in a tunnel still has
  /// to know where to go next. `app_dispatcher` binds `RemoteSolverOptimizer`,
  /// which sends the stops to a solver — a better answer, and one that needs a
  /// network. Both pass the same contract kit, and `routing_application` does
  /// not change a line between them.
  @lazySingleton
  RouteOptimizerPort optimizer() => const LocalHeuristicOptimizer();

  /// Traffic, over REST.
  @lazySingleton
  TrafficDataPort traffic(HttpTransport transport) =>
      RestTrafficData(transport: transport);

  /// The plan, cached on the device.
  @lazySingleton
  RouteCache routeCache(KeyValueStore store) =>
      KeyValueRouteCache(store: store);

  /// Where the van is.
  @lazySingleton
  LocationStreamPort locationStream(LocationSource source) =>
      DeviceLocationStream(source: source);

  /// Ordering a day's stops.
  @lazySingleton
  PlanRoute plan(
    RouteOptimizerPort optimizer,
    TrafficDataPort traffic,
    RouteCache cache,
    Clock clock,
    IdGenerator ids,
    Logger logger,
  ) => PlanRoute(
    optimizer: optimizer,
    traffic: traffic,
    cache: cache,
    clock: clock,
    ids: ids,
    logger: logger,
  );

  /// Where to go now.
  @lazySingleton
  NextStop nextStop(RouteCache cache) => NextStop(cache: cache);

  /// Replanning when the van deviates.
  @lazySingleton
  RecalculateOnDeviation recalculate(
    RouteCache cache,
    LocationStreamPort location,
    PlanRoute plan,
    Logger logger,
  ) => RecalculateOnDeviation(
    cache: cache,
    location: location,
    planRoute: plan,
    logger: logger,
  );

  /// Reading the plan without changing it.
  @lazySingleton
  CurrentPlan currentPlan(RouteCache cache) => CurrentPlan(cache: cache);

  /// The one stream routing announces on.
  ///
  /// Routing's driving surface is three interfaces and its change stream is
  /// one fact, so the channel is bound here and handed to every coordinator
  /// this app builds.
  @lazySingleton
  RouteChannel get routeChannel => RouteChannel();

  /// What both audiences perform.
  @lazySingleton
  RoutePlanning routePlanning(
    PlanRoute plan,
    CurrentPlan currentPlan,
    RouteChannel channel,
  ) => RoutePlanningCoordinator(
    planRoute: plan,
    currentPlan: currentPlan,
    channel: channel,
  );

  /// What only the vehicle on the route performs.
  ///
  /// **`RouteSupervision` is not bound here, and that is the split working in
  /// the other direction.** A courier does not reorder somebody's afternoon,
  /// so this app composes no `Resequence` — exactly as `app_dispatcher`
  /// composes no `RecalculateOnDeviation` and therefore needs no GPS.
  @lazySingleton
  RouteFollowing routeFollowing(
    NextStop nextStop,
    RecalculateOnDeviation recalculate,
    RouteChannel channel,
  ) => RouteFollowingCoordinator(
    nextStop: nextStop,
    recalculate: recalculate,
    channel: channel,
  );

  // -- sync ----------------------------------------------------------------

  /// **Scenario 5, row 3.** The outbox is a SQLite table, because a courier's
  /// writes have to survive the app being killed in a lift.
  /// `app_dispatcher` binds `InMemoryOutboxStore`: a dispatcher is online, and
  /// a queue that outlives their browser tab would be a queue nobody drains.
  @lazySingleton
  OutboxStore outbox(PeykDatabase database, Clock clock) => DriftOutboxStore(
    entries: database.outboxDao,
    values: database.keyValueDao,
    clock: clock,
  );

  /// Sending the queue.
  @lazySingleton
  CommandTransportPort commandTransport(HttpTransport transport) =>
      HttpCommandTransport(transport: transport);

  /// How far this device's clock is from the server's.
  @lazySingleton
  ClockSkewPort skew(HttpTransport transport, Clock clock) =>
      HttpClockSkew(transport: transport, clock: clock);

  /// Queueing a write.
  @lazySingleton
  EnqueueCommand enqueue(
    OutboxStore store,
    Clock clock,
    IdGenerator ids,
    Logger logger,
  ) => EnqueueCommand(store: store, clock: clock, ids: ids, logger: logger);

  /// What the badge shows.
  @lazySingleton
  ReadSyncStatus syncStatus(
    OutboxStore store,
    NetworkStatus network,
    Clock clock,
  ) => ReadSyncStatus(store: store, network: network, clock: clock);

  /// Draining it.
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

  /// What gave up.
  @lazySingleton
  LoadReviewQueue reviewQueue(OutboxStore store) =>
      LoadReviewQueue(store: store);

  /// What to do about it.
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

  // -- delivery ------------------------------------------------------------

  /// **Scenario 5, row 4.** Evidence is encrypted on the device, because a
  /// signature captured in a basement has to be kept until the queue drains.
  /// `app_dispatcher` binds `RemoteProofStore`: a dispatcher's browser has no
  /// proof to keep and no business holding somebody's signature.
  @lazySingleton
  ProofStorePort proofs(KeyValueStore store) =>
      LocalEncryptedProofStore(store: store);

  /// Whether the courier is at the address.
  @lazySingleton
  GeoFencePort fence(HttpTransport transport, LocationSource location) =>
      HttpGeoFence(transport: transport, location: location);

  /// Getting a photograph under the size a queued write can carry.
  @lazySingleton
  MediaCompressorPort get compressor => const BudgetMediaCompressor();

  /// The operation's attempts.
  @lazySingleton
  DeliveryGateway deliveryGateway(HttpTransport transport) =>
      RestDeliveryGateway(transport: transport);

  /// Arriving.
  @lazySingleton
  StartAttempt start(GeoFencePort fence, Clock clock, IdGenerator ids) =>
      StartAttempt(fence: fence, clock: clock, ids: ids);

  /// Handing over. Scenario 3: it queues through `sync` and publishes an event.
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

  /// Not handing over.
  @lazySingleton
  FailWithReason fail(SyncFacade sync, Clock clock) =>
      FailWithReason(sync: sync, clock: clock);

  /// Reading an attempt.
  @lazySingleton
  AttemptReads attemptReads(DeliveryGateway gateway) =>
      AttemptReads(gateway: gateway);

  /// The one stream delivery announces on.
  @lazySingleton
  DeliveryChannel get deliveryChannel => DeliveryChannel();

  /// Arriving at a door.
  ///
  /// The one delivery role that needs a device. `app_dispatcher` does not
  /// bind it, which is why that app needs no geofence and no GPS.
  @lazySingleton
  DeliveryExecution deliveryExecution(
    StartAttempt start,
    DeliveryChannel channel,
  ) => DeliveryExecutionCoordinator(startAttempt: start, channel: channel);

  /// Closing an attempt.
  @lazySingleton
  DeliverySettlement deliverySettlement(
    CompleteWithProof complete,
    FailWithReason fail,
    DeliveryChannel channel,
  ) => DeliverySettlementCoordinator(
    complete: complete,
    fail: fail,
    channel: channel,
  );

  /// Reading attempts back.
  @lazySingleton
  DeliveryHistory deliveryHistory(
    AttemptReads reads,
    DeliveryChannel channel,
  ) => DeliveryHistoryCoordinator(reads: reads, channel: channel);

  // -- payments ------------------------------------------------------------

  /// **Scenario 5, row 5, and the row where the two apps agree.**
  /// `RestPaymentsGateway` in both, because money goes to one place however it
  /// was taken. A table where every row differed would be a table describing a
  /// rule; this one describes decisions.
  @lazySingleton
  PaymentsGateway paymentsGateway(HttpTransport transport) =>
      RestPaymentsGateway(transport: transport);

  /// The cash in the courier's pocket, counted on the device.
  @lazySingleton
  CashDrawerPort drawer(KeyValueStore store) =>
      KeyValueCashDrawer(store: store);

  /// Receipts, kept until the queue drains.
  @lazySingleton
  ReceiptPrinterPort receipts(KeyValueStore store) =>
      KeyValueReceiptPrinter(store: store);

  /// The day's total.
  @lazySingleton
  SettlementStore settlements(KeyValueStore store) =>
      KeyValueSettlementStore(store: store);

  /// Taking money.
  @lazySingleton
  CollectOnDelivery collect(
    PaymentsGateway gateway,
    CashDrawerPort drawer,
    ReceiptPrinterPort receipts,
    SettlementStore settlements,
    SyncFacade sync,
    Clock clock,
    IdGenerator ids,
    Logger logger,
  ) => CollectOnDelivery(
    gateway: gateway,
    drawer: drawer,
    receipts: receipts,
    settlements: settlements,
    sync: sync,
    clock: clock,
    ids: ids,
    logger: logger,
  );

  /// Giving it back.
  @lazySingleton
  RefundCollection refund(
    PaymentsGateway gateway,
    CashDrawerPort drawer,
    SettlementStore settlements,
    Clock clock,
    Logger logger,
  ) => RefundCollection(
    gateway: gateway,
    drawer: drawer,
    settlements: settlements,
    clock: clock,
    logger: logger,
  );

  /// Handing the day in.
  @lazySingleton
  CloseDailySettlement closeDay(SettlementStore settlements, Clock clock) =>
      CloseDailySettlement(settlements: settlements, clock: clock);

  /// What is owed.
  @lazySingleton
  PaymentStatusOf statusOf(PaymentsGateway gateway) =>
      PaymentStatusOf(gateway: gateway);

  /// The coordinator, once.
  @lazySingleton
  PaymentsCoordinator paymentsCoordinator(
    CollectOnDelivery collect,
    RefundCollection refund,
    CloseDailySettlement closeDay,
    PaymentStatusOf statusOf,
  ) => PaymentsCoordinator(
    collect: collect,
    refund: refund,
    closeDay: closeDay,
    statusOf: statusOf,
  );

  /// Collecting.
  @lazySingleton
  PaymentsFacade payments(PaymentsCoordinator it) => it;

  /// The port shipments reads. Scenario 1, and no cycle.
  @lazySingleton
  PaymentStatusReader statusReader(PaymentsCoordinator it) => it;

  /// Scenario 2's listener, registered and started by `CourierWatchers`.
  @lazySingleton
  CollectionReconciler reconciler(
    DomainEventBus events,
    PaymentsGateway gateway,
    SettlementStore settlements,
    Logger logger,
  ) => CollectionReconciler(
    events: events,
    gateway: gateway,
    settlements: settlements,
    logger: logger,
  );
}
