import 'package:core_ports/core_ports.dart';
import 'package:injectable/injectable.dart';
import 'package:payments_api/payments_api.dart';
import 'package:payments_application/payments_application.dart';
import 'package:payments_testing/payments_testing.dart';
import 'package:sync_api/sync_api.dart';

/// payments, on fakes.
///
/// The other half of scenario 1. `HarnessShipments` hands `AdvanceShipment` a
/// `PaymentStatusReader` from this feature's contract; this module hands
/// `CollectOnDelivery` nothing of shipments'. Neither application package
/// names the other, and the two contracts name no implementation, so the graph
/// stays acyclic while both features get what they need.
///
/// Scenario 2 is the `CollectionReconciler` at the bottom. It listens for
/// `DeliveryCompleted` on the `DomainEventBus` and closes the matching
/// collection. `delivery_application` publishes that event and has never heard
/// of payments; payments listens and has never heard of delivery.
@module
abstract class HarnessPayments {
  /// The operation's collections, in a map.
  ///
  /// Scenario 5, last row: both product apps bind `RestPaymentsGateway`. The
  /// row where two apps agree is worth as much as the rows where they differ —
  /// it is what shows the table is a record of decisions rather than a rule
  /// that every port must vary.
  @lazySingleton
  FakePaymentsGateway get fakeGateway => FakePaymentsGateway();

  /// The same instance, as the port.
  @lazySingleton
  PaymentsGateway gateway(FakePaymentsGateway fake) => fake;

  /// The cash a courier is carrying, counted in memory.
  ///
  /// Starts empty, which is what a drawer at the beginning of a shift holds.
  /// The fake asks for the opening balance rather than defaulting it, and that
  /// is the right shape for a test: a drawer that started at some arbitrary
  /// figure would make every assertion about a total relative to a number
  /// nobody chose.
  @lazySingleton
  CashDrawerPort get drawer =>
      FakeCashDrawer(const Money.zero(Currency.tryLira));

  /// A printer that keeps its receipts instead of printing them.
  @lazySingleton
  ReceiptPrinterPort get receipts => FakeReceiptPrinter();

  /// The day's totals.
  @lazySingleton
  SettlementStore get settlements => InMemorySettlementStore();

  /// Taking money at a door.
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

  /// What is owed on one parcel.
  @lazySingleton
  PaymentStatusOf statusOf(PaymentsGateway gateway) =>
      PaymentStatusOf(gateway: gateway);

  /// The port `shipments` reads through, and the reason scenario 1 has no
  /// cycle in it.
  @lazySingleton
  PaymentStatusReader statusReader(PaymentsCoordinator it) => it;

  /// The coordinator, registered once.
  @lazySingleton
  PaymentsCoordinator coordinator(
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

  /// Collecting and refunding.
  @lazySingleton
  PaymentsFacade payments(PaymentsCoordinator it) => it;

  /// Scenario 2: the watcher that closes a collection when a delivery lands.
  ///
  /// Registered but **not started here**. `HarnessWatchers` starts every
  /// listener in this app and is the one thing that can stop them, because two
  /// of the three hand their subscription back to whoever started them. A
  /// module that started this one would leave the app with two places that
  /// know about listening and one that can stop it.
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
