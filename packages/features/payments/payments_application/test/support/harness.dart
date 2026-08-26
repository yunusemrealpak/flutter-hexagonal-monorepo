import 'package:core_testing/core_testing.dart';
import 'package:payments_application/payments_application.dart';
import 'package:payments_testing/payments_testing.dart';
import 'package:sync_testing/sync_testing.dart';

/// Everything a payments use case needs, all of it fake.
///
/// Assembled here rather than in each test's `setUp`, because the interesting
/// part of these tests is the *order* the use cases do things in and what they
/// do when one step fails — and a twenty-line arrangement in front of every
/// one of them buries both.
final class Harness {
  /// Builds the harness with a fixed clock and a counting id generator.
  Harness()
    : clock = FakeClock(PaymentsFixtures.noon),
      ids = FakeIdGenerator('pay');

  /// The operation's record of the money it has taken.
  final FakePaymentsGateway gateway = FakePaymentsGateway();

  /// What the courier is physically holding.
  final FakeCashDrawer drawer = FakeCashDrawer(PaymentsFixtures.noLira);

  /// What gives the customer something to keep.
  final FakeReceiptPrinter receipts = FakeReceiptPrinter();

  /// Where the day is kept.
  final InMemorySettlementStore settlements = InMemorySettlementStore();

  /// The outbox a cash collection falls back to.
  final FakeSyncFacade queue = FakeSyncFacade();

  /// The bus `DeliveryCompleted` arrives on.
  final RecordingEventBus events = RecordingEventBus();

  /// What the use cases log to.
  final RecordingLogger logger = RecordingLogger();

  /// Time, which only moves when a test moves it.
  final FakeClock clock;

  /// Identifiers, which count rather than being random.
  final FakeIdGenerator ids;

  /// The use case that takes money at a door.
  CollectOnDelivery get collect => CollectOnDelivery(
    gateway: gateway,
    drawer: drawer,
    receipts: receipts,
    settlements: settlements,
    sync: queue,
    clock: clock,
    ids: ids,
    logger: logger,
  );

  /// The use case that gives it back.
  RefundCollection get refund => RefundCollection(
    gateway: gateway,
    drawer: drawer,
    settlements: settlements,
    clock: clock,
    logger: logger,
  );

  /// The use case that hands in a day.
  CloseDailySettlement get closeDay =>
      CloseDailySettlement(settlements: settlements, clock: clock);

  /// The read side.
  PaymentStatusOf get statusOf => PaymentStatusOf(gateway: gateway);

  /// The subscriber that closes a collection when its delivery completes.
  CollectionReconciler get reconciler => CollectionReconciler(
    events: events,
    gateway: gateway,
    settlements: settlements,
    logger: logger,
  );

  /// The facade, wired the way a composition root would wire it.
  PaymentsCoordinator get coordinator => PaymentsCoordinator(
    collect: collect,
    refund: refund,
    closeDay: closeDay,
    statusOf: statusOf,
  );

  /// Releases what the harness holds open.
  Future<void> dispose() async {
    await queue.dispose();
    await events.dispose();
  }
}
