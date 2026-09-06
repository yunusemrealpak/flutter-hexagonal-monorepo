import 'package:shipments_api/shipments_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// What can be asked of the counting screen.
///
/// Four cases, and one of them is fired by a device rather than by a person:
/// [ParcelScanned] arrives every time a trigger is pulled, several times a
/// second, from a scanner that does not wait to be asked. That is what makes
/// the transformers on this bloc load-bearing rather than decorative.
sealed class CountEvent {
  const CountEvent();
}

/// Pick up a count that was already open.
final class CountResumed extends CountEvent {
  /// Creates the event.
  const CountResumed();
}

/// Open a count against the depot's manifest.
final class CountStarted extends CountEvent {
  /// Creates the event.
  const CountStarted(this.direction);

  /// Whether the van is being loaded or unloaded.
  final LoadDirection direction;
}

/// Record one scan.
final class ParcelScanned extends CountEvent {
  /// Creates the event.
  const ParcelScanned(this.shipment);

  /// What the trigger read.
  final ShipmentId shipment;
}

/// Close the count, discrepancy and all.
final class CountFinished extends CountEvent {
  /// Creates the event.
  const CountFinished();
}
