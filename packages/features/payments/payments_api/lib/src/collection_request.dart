import 'package:identity_api/identity_api.dart';
import 'package:meta/meta.dart';
import 'package:shipments_api/shipments_api.dart';

import 'money.dart';
import 'payment_method.dart';

/// What is to be collected, from whom, against which parcel.
///
/// A value rather than an entity: it has no identity of its own and never
/// changes. The thing with an identity is the *attempt* to satisfy it, and its
/// identity is the idempotency key.
///
/// [shipment] and [courier] are identifiers from two other features and are
/// the only foreign types on this class. There is no `Shipment` here and no
/// `ShipmentSummary`: payments never learns what is in a parcel or where it is
/// going, only that money is owed against one.
@immutable
final class CollectionRequest {
  /// Describes a collection.
  const CollectionRequest({
    required this.shipment,
    required this.courier,
    required this.amount,
    required this.method,
  });

  /// Which parcel the money is owed against.
  final ShipmentId shipment;

  /// Who is collecting it.
  final ActorId courier;

  /// How much.
  final Money amount;

  /// How it changes hands.
  final PaymentMethod method;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionRequest &&
          other.shipment == shipment &&
          other.courier == courier &&
          other.amount == amount &&
          other.method == method;

  @override
  int get hashCode => Object.hash(shipment, courier, amount, method);

  @override
  String toString() => 'CollectionRequest(${shipment.value}, $amount)';
}
