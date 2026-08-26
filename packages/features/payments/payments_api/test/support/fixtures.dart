import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Fixtures for this package's own tests.
///
/// They live here rather than in `payments_testing`, because that package
/// depends on this one and the arrow cannot run both ways.
///
/// Nothing here calls `DateTime.now()` — rule A1. A settlement whose day
/// depends on when the suite ran is a settlement no assertion can pin down.
abstract final class Fixtures {
  /// The instant every fixture measures from.
  static final DateTime noon = DateTime.utc(2026, 3, 14, 12);

  /// A shipment, by identifier.
  static ShipmentId shipment([String raw = 'SHP-1']) =>
      unwrap(ShipmentId.parse(raw));

  /// A courier, by identifier.
  static ActorId courier([String raw = 'courier-1']) =>
      unwrap(ActorId.parse(raw));

  /// An idempotency key.
  static IdempotencyKey key([String raw = 'pay-1']) =>
      unwrap(IdempotencyKey.parse(raw));

  /// An amount in lira.
  static Money lira(int minorUnits) =>
      unwrap(Money.of(minorUnits: minorUnits, currency: Currency.tryLira));

  /// An amount in euro.
  static Money euro(int minorUnits) =>
      unwrap(Money.of(minorUnits: minorUnits, currency: Currency.eur));

  /// What is to be collected.
  static CollectionRequest request({
    int minorUnits = 4500,
    PaymentMethod method = const PaymentMethod.cash(),
    String shipmentId = 'SHP-1',
  }) => CollectionRequest(
    shipment: shipment(shipmentId),
    courier: courier(),
    amount: lira(minorUnits),
    method: method,
  );

  /// A pending attempt.
  static PaymentAttempt attempt({
    String keyValue = 'pay-1',
    int minorUnits = 4500,
    PaymentMethod method = const PaymentMethod.cash(),
  }) => PaymentAttempt.intending(
    key: key(keyValue),
    request: request(minorUnits: minorUnits, method: method),
  );

  /// An attempt whose money changed hands.
  static PaymentAttempt taken({
    String keyValue = 'pay-1',
    int minorUnits = 4500,
    PaymentMethod method = const PaymentMethod.cash(),
  }) => unwrap(
    attempt(
      keyValue: keyValue,
      minorUnits: minorUnits,
      method: method,
    ).taken(at: noon),
  );

  /// An open day for the default courier.
  static Settlement day() => unwrap(
    Settlement.openFor(
      courier: courier(),
      day: noon,
      zero: const Money.zero(Currency.tryLira),
    ),
  );

  /// Unwraps a `Result`, failing loudly rather than returning a default.
  static T unwrap<T, F>(Result<T, F> result) =>
      result.fold((value) => value, (failure) => throw StateError('$failure'));
}
