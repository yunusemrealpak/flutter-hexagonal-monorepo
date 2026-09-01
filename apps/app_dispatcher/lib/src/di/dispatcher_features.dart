import 'package:core_ports/core_ports.dart';
import 'package:delivery_api/delivery_api.dart';
import 'package:delivery_application/delivery_application.dart';
import 'package:delivery_infrastructure/delivery_infrastructure.dart';
import 'package:http_dio/http_dio.dart';
import 'package:identity_api/identity_api.dart';
import 'package:identity_application/identity_application.dart';
import 'package:identity_infrastructure/identity_infrastructure.dart';
import 'package:injectable/injectable.dart';
import 'package:payments_api/payments_api.dart';
import 'package:payments_application/payments_application.dart';
import 'package:payments_infrastructure/payments_infrastructure.dart';
import 'package:routing_api/routing_api.dart';
import 'package:routing_application/routing_application.dart';
import 'package:routing_infrastructure/routing_infrastructure.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:shipments_application/shipments_application.dart';
import 'package:shipments_infrastructure/shipments_infrastructure.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_application/sync_application.dart';
import 'package:sync_infrastructure/sync_infrastructure.dart';
import 'package:sync_testing/sync_testing.dart';

/// The six full-split features, on the adapters a desk needs.
///
/// **This file is the second column of the table in §5.5.** Set it beside
/// `CourierFeatures` and the diff is the point: four bindings differ, one is
/// deliberately the same, and every `_application` package is byte-for-byte
/// identical between the two. That is the claim scenario 5 makes, and a diff
/// is the only honest way to check it.
@module
abstract class DispatcherFeatures {
  // -- identity ------------------------------------------------------------

  /// **Scenario 5, row 2.** A dispatcher signs in at whatever desk they are
  /// sitting at, through the operation's identity provider — so the gateway
  /// speaks to a realm rather than to a registered handset. `app_courier`
  /// binds `DeviceBoundCredentialGateway`, because a courier's password is
  /// worth nothing without their phone and a desk has no such guarantee.
  @lazySingleton
  CredentialGateway gateway(HttpTransport transport) =>
      SsoCredentialGateway(transport: transport, realm: 'peyk-operations');

  /// The session, in the keychain.
  @lazySingleton
  SessionStore sessions(SecureStore store) => SecureSessionStore(store: store);

  /// This installation's registration.
  ///
  /// Present even though this app does not bind credentials to a device: the
  /// port is on identity's contract and `IdentityCoordinator` takes it. What
  /// it records here is which desk somebody signed in at, which is worth
  /// having and is not what it means on a phone.
  @lazySingleton
  DeviceRegistry devices(
    KeyValueStore store,
    IdGenerator ids,
    Clock clock,
  ) => InstallationDeviceRegistry(
    store: store,
    ids: ids,
    clock: clock,
    fingerprint: 'dispatcher-handset',
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
  ///
  /// Registered under its concrete type as well as the port, because
  /// `RemoteBarcodeResolver` names the class rather than the interface. Both
  /// registrations resolve to one object, which is what keeps that safe — and
  /// the adapter naming a concrete adapter is worth a second look, since it is
  /// the one place in the workspace where an infrastructure class depends on a
  /// sibling rather than on a contract.
  @lazySingleton
  RestShipmentGateway restShipments(HttpTransport transport) =>
      RestShipmentGateway(transport: transport);

  /// The same instance, as the port the use cases take.
  @lazySingleton
  ShipmentGateway shipmentGateway(RestShipmentGateway it) => it;

  /// The cache, in the desk's key-value table.
  ///
  /// `FindShipment` takes it in both apps and means something different in
  /// each: on a phone it is what a courier reads in a basement, and here it is
  /// what keeps a board of two hundred rows from re-fetching every parcel a
  /// dispatcher scrolls past.
  @lazySingleton
  ShipmentCache shipmentCache(KeyValueStore store) =>
      KeyValueShipmentCache(store: store);

  /// **Two adapters for one port, and this app binds the remote one.**
  ///
  /// A dispatcher scanning a parcel at the depot is looking for one that may
  /// not be on any manifest yet, so the resolver asks the operation.
  /// `app_courier` binds `ManifestBarcodeResolver`, which answers from the
  /// cached manifest without a network — the whole point on a phone, and
  /// useless here.
  @lazySingleton
  BarcodeResolverPort barcodes(RestShipmentGateway gateway) =>
      RemoteBarcodeResolver(gateway: gateway);

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

  /// **Scenario 5, row 1, and scenario 4's payoff.** A desk is online, so the
  /// stops go to a solver in a data centre — a better ordering than a 2-opt
  /// sweep, and one that needs a network. `app_courier` binds
  /// `LocalHeuristicOptimizer`, because a courier in a tunnel still has to
  /// know where to go next.
  ///
  /// Both implementations pass the same contract kit, and
  /// `routing_application` does not change a line between them. That is the
  /// whole of scenario 4, and it is only visible with two apps in front of
  /// you.
  @lazySingleton
  RouteOptimizerPort optimizer(HttpTransport transport) =>
      RemoteSolverOptimizer(transport: transport);

  /// Traffic, over REST.
  @lazySingleton
  TrafficDataPort traffic(HttpTransport transport) =>
      RestTrafficData(transport: transport);

  /// The plan, cached on the device.
  @lazySingleton
  RouteCache routeCache(KeyValueStore store) =>
      KeyValueRouteCache(store: store);

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

  /// Changing the order.
  @lazySingleton
  Resequence resequence(RouteCache cache) => Resequence(cache: cache);

  /// Reading the plan without changing it.
  @lazySingleton
  CurrentPlan currentPlan(RouteCache cache) => CurrentPlan(cache: cache);

  /// The one stream routing announces on.
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

  /// A desk's override of a route it is not driving.
  ///
  /// **The registration that used to force a GPS into this app.** Until phase
  /// 8 routing had one driving port declaring every operation, so composing
  /// `resequence` meant also supplying `RecalculateOnDeviation` and the
  /// `LocationStreamPort` behind it — a port whose only honest answer here is
  /// the desk's own position. `RouteFollowing` is a separate interface now and
  /// this app does not compose it, so the question no longer arises.
  @lazySingleton
  RouteSupervision routeSupervision(
    Resequence resequence,
    RouteChannel channel,
  ) => RouteSupervisionCoordinator(resequence: resequence, channel: channel);

  // -- sync ----------------------------------------------------------------

  /// **Scenario 5, row 3, and the one binding that looks like a downgrade.**
  ///
  /// This app has a database — it binds one for the key-value store two lines
  /// of `DispatcherPorts` above — so the outbox is in memory by *choice*, not
  /// by absence. A dispatcher is online: their writes go out in the same
  /// second, and a queue that outlived a session would be a queue nobody
  /// drains and everybody inherits. `app_courier` binds `DriftOutboxStore`
  /// because a courier's writes have to survive the app being killed in a lift.
  ///
  /// It comes from `sync_testing`, and that is worth being uncomfortable about
  /// for a moment: a `_testing` package in a production app. The alternative
  /// would be a second in-memory implementation in `sync_infrastructure` that
  /// differs from this one in nothing, and then two of them to keep in step
  /// with one contract kit. The specification's table names this class, and
  /// the contract kit runs against it.
  @lazySingleton
  OutboxStore get outbox => InMemoryOutboxStore();

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

  /// **Scenario 5, row 4.** A dispatcher reads evidence and never captures it,
  /// so the store is the operation's. Keeping a copy of somebody's signature
  /// on a desk would be a second place it exists and a second place it leaks.
  /// `app_courier` binds `LocalEncryptedProofStore`, because a signature taken
  /// in a basement has to be kept until the queue drains.
  @lazySingleton
  ProofStorePort proofs(HttpTransport transport) =>
      RemoteProofStore(transport: transport);

  /// Getting a photograph under the size a queued write can carry.
  ///
  /// Bound although this app has no camera, and that is not the same kind of
  /// binding the GPS used to be. A desk composes `DeliverySettlement` because
  /// correcting a record is something a desk genuinely does, and settling an
  /// attempt whose proof carries a photograph has to compress it wherever the
  /// call was made. The compressor answers a question about *bytes*, not about
  /// where the caller is standing — so this app can answer it honestly.
  @lazySingleton
  MediaCompressorPort get compressor => const BudgetMediaCompressor();

  /// The operation's attempts.
  @lazySingleton
  DeliveryGateway deliveryGateway(HttpTransport transport) =>
      RestDeliveryGateway(transport: transport);

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

  /// Closing an attempt — a desk's correction of somebody else's afternoon.
  ///
  /// **`DeliveryExecution` is not bound here, and that is the whole of what
  /// phase 8 changed in this app.** Opening an attempt asks a `GeoFencePort`
  /// whether *this device* is at the address; a desk has no answer to that.
  /// Until the split, one coordinator took all four use cases, so this app had
  /// to bind `StartAttempt`, `HttpGeoFence` and a `LocationSource` over the
  /// desk's own GPS in order to read an attempt back. Those three bindings are
  /// gone, and `location_service` is no longer a dependency of this app.
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

  /// Reading attempts back — the half of delivery a board is made of.
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

  /// The cash in the dispatcher's pocket, counted on the device.
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

  /// Scenario 2's listener, registered and started by `DispatcherWatchers`.
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
