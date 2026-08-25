import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

/// A fixed instant every test in this package measures from.
///
/// A constant rather than a clock. Nothing here calls `DateTime.now()` — rule
/// A1 — and a state machine whose rules take `at` as a parameter is one that
/// never needs a test to wait for anything.
final noon = DateTime.utc(2026, 3, 14, 12);

/// Unwraps a [Result] in test setup, where a failure means the fixture itself
/// is wrong and the test has nothing left to say.
T unwrap<T, F>(Result<T, F> result) =>
    result.fold((value) => value, (failure) => throw StateError('$failure'));

/// A courier, by identifier.
ActorId courier([String raw = 'courier-1']) => unwrap(ActorId.parse(raw));

/// A barcode whose check digit is computed rather than guessed.
///
/// Hard-coding a valid number would make every test that changed [body] fail
/// for a reason unrelated to what it was testing.
Barcode barcode([String body = '10000000000']) =>
    unwrap(Barcode.parse('$body${Barcode.checkDigitFor(body)}'));

/// A consignee at a plausible address.
Consignee consignee({String name = 'Ayse Yilmaz'}) => unwrap(
  Consignee.create(
    name: name,
    address: unwrap(
      AddressPoint.create(
        formatted: 'Bagdat Cd. 100, Kadikoy, Istanbul',
        latitude: 40.96,
        longitude: 29.06,
      ),
    ),
    phone: '+90 555 000 0000',
  ),
);

/// A newly accepted shipment.
Shipment accepted({String id = 'ship-1'}) => Shipment.accepted(
  id: unwrap(ShipmentId.parse(id)),
  barcode: barcode(),
  consignee: consignee(),
);

/// A shipment driven forward through the machine to [stop], one legal move at
/// a time.
///
/// Building the state directly instead would let a test assert against a
/// shipment the machine cannot actually produce, which is the failure mode a
/// state machine test is most exposed to.
Shipment at(ShipmentStatus stop, {ActorId? by}) {
  final who = by ?? courier();
  var shipment = accepted();
  if (stop is ShipmentAwaitingAssignment) return shipment;

  shipment = unwrap(shipment.assignTo(who, at: noon));
  if (stop is ShipmentAssignedToCourier) return shipment;

  shipment = unwrap(shipment.loadOnto(who, at: noon));
  if (stop is ShipmentLoadedOnVehicle) return shipment;

  shipment = unwrap(shipment.startDelivery(who, at: noon));
  if (stop is ShipmentOutForDelivery) return shipment;

  return switch (stop) {
    ShipmentDeliveredToConsignee(:final proofReference) => unwrap(
      shipment.completeDelivery(proofReference: proofReference, at: noon),
    ),
    ShipmentUndeliverable(:final reason) => unwrap(
      shipment.failDelivery(reason: reason, at: noon),
    ),
    ShipmentReturnedToDepot() => unwrap(
      shipment.returnToDepot(at: noon, by: who),
    ),
    _ => shipment,
  };
}

/// Every state, each built by walking the machine to it.
///
/// The list a transition-table test iterates over, so that adding a state to
/// the union without deciding what may follow it fails a test rather than
/// passing silently.
List<ShipmentStatus> get everyState => [
  const ShipmentStatus.awaitingAssignment(),
  ShipmentStatus.assignedToCourier(courier()),
  ShipmentStatus.loadedOnVehicle(courier()),
  ShipmentStatus.outForDelivery(courier()),
  ShipmentStatus.deliveredToConsignee(proofReference: 'proof-1', at: noon),
  ShipmentStatus.undeliverable(reason: 'nobody home', at: noon),
  ShipmentStatus.returnedToDepot(at: noon),
];
