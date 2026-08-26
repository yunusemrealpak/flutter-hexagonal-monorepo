import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';

import 'payments_fixtures.dart';

/// A `PaymentsGateway` that really takes money once.
///
/// **The idempotency is the point of this fake.** `collect` stores by the
/// attempt's key and, when it already has that key, returns what it stored
/// rather than recording anything new. That is not a shortcut around writing a
/// server: it is the behaviour the port promises, and a fake that recorded
/// twice would let a use case with a double-charge bug pass its tests.
///
/// It is also the adapter `app_harness` binds — scenario 5's table says so —
/// which is why it lives in a package apps may depend on.
///
/// The refund instant comes from `refundedAt` rather than from a clock: rule
/// A1 forbids the ambient version here as everywhere outside `apps/`, and a
/// real adapter reads the instant the server reported anyway.
final class FakePaymentsGateway implements PaymentsGateway {
  /// Creates the gateway, stamping refunds at [refundedAt].
  FakePaymentsGateway({DateTime? refundedAt})
    : _refundedAt = refundedAt ?? PaymentsFixtures.noon;

  final DateTime _refundedAt;
  final Map<String, PaymentAttempt> _byKey = {};
  final Map<String, String> _keyByShipment = {};
  final List<PaymentsFailure> _queuedFailures = [];

  /// How many attempts were actually recorded, as opposed to asked for.
  ///
  /// The assertion behind "one intention, one movement of money": a use case
  /// that retried three times should leave this at one.
  int get recorded => _byKey.length;

  /// Every key this gateway holds.
  List<String> get keys => List.unmodifiable(_byKey.keys);

  /// Makes the next call return [failure].
  void failNextWith(PaymentsFailure failure) => _queuedFailures.add(failure);

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> collect(
    PaymentAttempt attempt,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    // The whole contract, in three lines. A second copy of one intention is
    // answered with the first one's result, so a courier's retry in a tunnel
    // is free and a lost acknowledgement costs nobody anything.
    final stored = _byKey[attempt.id.value];
    if (stored != null) return Success(stored);

    _byKey[attempt.id.value] = attempt;
    _keyByShipment[attempt.request.shipment.value] = attempt.id.value;
    return Success(attempt);
  }

  @override
  Future<Result<PaymentAttempt, PaymentsFailure>> refund(String key) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    final stored = _byKey[key];
    if (stored == null) return Failed(NoCollectionFor(key));

    // Refunding is idempotent for the same reason collecting is: a courier
    // whose refund request timed out will send it again, and giving the money
    // back twice is the same loss as taking it twice.
    if (stored.outcome case PaymentRefunded()) return Success(stored);

    return stored.refunded(at: _refundedAt).map((refunded) {
      _byKey[key] = refunded;
      return refunded;
    });
  }

  @override
  Future<Result<PaymentAttempt?, PaymentsFailure>> attemptFor(
    String shipmentId,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    // A parcel nobody has collected against is a successful read of nothing.
    // Most parcels are prepaid, so a failure here would make the ordinary case
    // an error.
    final key = _keyByShipment[shipmentId];
    return Success(key == null ? null : _byKey[key]);
  }

  PaymentsFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
