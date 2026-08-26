import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:payments_api/payments_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// Fixtures for payments, shared by this package's contract kits and by every
/// package that consumes them.
///
/// Everything is deterministic and nothing calls `DateTime.now()` — rule A1. A
/// settlement whose day depends on when the suite ran is a settlement no
/// assertion can pin down.
///
/// Amounts are in minor units, because `Money` is: 4500 is forty-five lira.
/// Spelling it that way in a fixture is a small, constant reminder that a
/// number in this feature is never a float.
abstract final class PaymentsFixtures {
  /// The instant every fixture measures from.
  static final DateTime noon = DateTime.utc(2026, 3, 14, 12);

  /// Nothing, in lira.
  static const Money noLira = Money.zero(Currency.tryLira);

  /// A shipment, by identifier.
  static ShipmentId shipment([String raw = 'SHP-1']) =>
      _unwrap(ShipmentId.parse(raw));

  /// A courier, by identifier.
  static ActorId courier([String raw = 'courier-1']) =>
      _unwrap(ActorId.parse(raw));

  /// An idempotency key.
  static IdempotencyKey key([String raw = 'pay-1']) =>
      _unwrap(IdempotencyKey.parse(raw));

  /// An amount in lira.
  static Money lira(int minorUnits) =>
      _unwrap(Money.of(minorUnits: minorUnits, currency: Currency.tryLira));

  /// What is to be collected.
  static CollectionRequest request({
    int minorUnits = 4500,
    PaymentMethod method = const PaymentMethod.cash(),
    String shipmentId = 'SHP-1',
    String courierId = 'courier-1',
  }) => CollectionRequest(
    shipment: shipment(shipmentId),
    courier: courier(courierId),
    amount: lira(minorUnits),
    method: method,
  );

  /// A pending attempt.
  static PaymentAttempt attempt({
    String keyValue = 'pay-1',
    int minorUnits = 4500,
    PaymentMethod method = const PaymentMethod.cash(),
    String shipmentId = 'SHP-1',
  }) => PaymentAttempt.intending(
    key: key(keyValue),
    request: request(
      minorUnits: minorUnits,
      method: method,
      shipmentId: shipmentId,
    ),
  );

  /// An attempt whose money changed hands at [at], or at [noon].
  static PaymentAttempt taken({
    String keyValue = 'pay-1',
    int minorUnits = 4500,
    PaymentMethod method = const PaymentMethod.cash(),
    String shipmentId = 'SHP-1',
    DateTime? at,
  }) => _unwrap(
    attempt(
      keyValue: keyValue,
      minorUnits: minorUnits,
      method: method,
      shipmentId: shipmentId,
    ).taken(at: at ?? noon),
  );

  /// An open day for the default courier.
  static Settlement day({String courierId = 'courier-1'}) => _unwrap(
    Settlement.openFor(courier: courier(courierId), day: noon, zero: noLira),
  );

  static T _unwrap<T, F>(Result<T, F> result) =>
      result.fold((value) => value, (failure) => throw StateError('$failure'));
}
