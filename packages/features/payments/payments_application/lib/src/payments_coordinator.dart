import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'close_daily_settlement.dart';
import 'collect_on_delivery.dart';
import 'payment_status_of.dart';
import 'refund_collection.dart';

/// The driving ports' implementation: one intention per method, each of them a
/// call into a use case.
///
/// It satisfies **two** interfaces, and that is worth reading rather than
/// skimming. `PaymentsFacade` is what payments' own screens use;
/// `PaymentStatusReader` is the one narrow question `shipments` asks. A
/// composition root binds the same object to both, and `shipments_application`
/// receives it as the reader — so it can ask what is owed and cannot take
/// money, because the type it holds has no method for it.
///
/// Deliberately thin, like every coordinator in this workspace. Everything
/// that decides anything is behind it — the settle-once rule in
/// `PaymentAttempt`, the key binding in `CollectOnDelivery`, the cash-only
/// offline path. What this class adds is the shape of the ports and the change
/// stream.
final class PaymentsCoordinator implements PaymentsFacade, PaymentStatusReader {
  /// Creates the coordinator over its use cases.
  PaymentsCoordinator({
    required this._collect,
    required this._refund,
    required this._closeDay,
    required this._statusOf,
  });

  final CollectOnDelivery _collect;
  final RefundCollection _refund;
  final CloseDailySettlement _closeDay;
  final PaymentStatusOf _statusOf;

  final StreamController<PaymentAttempt> _changes =
      StreamController<PaymentAttempt>.broadcast();

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> collectOnDelivery({
    required ShipmentId shipment,
    required ActorId courier,
    required Money amount,
    required PaymentMethod method,
  }) => _announce(
    _collect((
      shipment: shipment,
      courier: courier,
      amount: amount,
      method: method,
    )),
  );

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> refund(IdempotencyKey key) =>
      _announce(_refund(key));

  @override
  Future<Result<Settlement, PaymentsFailure>> closeDailySettlement({
    required ActorId courier,
    required DateTime day,
  }) => _closeDay((courier: courier, day: day));

  @override
  Future<Result<PaymentStatus, PaymentsFailure>> paymentStatusOf(
    ShipmentId shipment,
  ) => _statusOf(shipment);

  /// The `PaymentStatusReader` half, and the same question.
  ///
  /// Two names for one answer rather than two implementations: a reader that
  /// went a different way to the same question would be a second place for the
  /// mapping from attempt to status to drift.
  @override
  Future<Result<PaymentStatus, PaymentsFailure>> statusFor(
    ShipmentId shipment,
  ) => paymentStatusOf(shipment);

  /// Emits an attempt whenever one moves.
  ///
  /// Nothing is emitted for a refused call: no money moved, and a screen that
  /// redrew on it would flicker for no reason.
  @override
  Stream<PaymentAttempt> changes() => _changes.stream;

  /// Releases the change stream.
  Future<void> dispose() => _changes.close();

  Future<Result<PaymentAttempt, PaymentsFailure>> _announce(
    Future<Result<PaymentAttempt, PaymentsFailure>> work,
  ) async {
    final result = await work;
    if (result case Success(value: final attempt)) _changes.add(attempt);
    return result;
  }
}
