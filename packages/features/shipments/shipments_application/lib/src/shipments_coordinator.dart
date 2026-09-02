import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';

import 'advance_shipment.dart';
import 'find_shipment.dart';
import 'load_manifest.dart';
import 'resolve_barcode.dart';
import 'shipment_move.dart';

/// The driving port's implementation: one intention per method, each of them
/// a call into a use case.
///
/// Deliberately thin. Everything that decides anything is behind it — the
/// state machine in `Shipment`, the read-or-fall-back rule in `FindShipment`,
/// the persist-and-publish sequence in `AdvanceShipment`. What this class adds
/// is the shape of the port and the change stream, and if it ever grows a
/// rule of its own that is the signal a use case is missing.
///
/// It is not called `ShipmentsFacadeImpl`. The name says what it does rather
/// than which interface it satisfies, which is the difference between a class
/// you can find by its job and one you can only find by its type.
final class ShipmentsCoordinator implements ShipmentsFacade {
  /// Creates the coordinator over its use cases.
  ///
  /// The use cases arrive built rather than being constructed here, so that an
  /// app's composition root decides which adapters are behind them and a test
  /// can substitute one without standing up the other three.
  ShipmentsCoordinator({
    required this._findShipment,
    required this._resolveBarcode,
    required this._loadManifest,
    required this._advanceShipment,
  });

  final FindShipment _findShipment;
  final ResolveBarcode _resolveBarcode;
  final LoadManifest _loadManifest;
  final AdvanceShipment _advanceShipment;

  final StreamController<Shipment> _changes =
      StreamController<Shipment>.broadcast();

  @override
  Future<Result<Shipment, ShipmentFailure>> byId(ShipmentId id) =>
      _findShipment(id);

  @override
  Future<Result<Shipment, ShipmentFailure>> byBarcode(Barcode barcode) =>
      _resolveBarcode(barcode);

  @override
  Future<Result<PageOf<ShipmentSummary>, ShipmentFailure>> manifestFor(
    ActorId courier, {
    PageRequest page = const PageRequest(),
  }) => _loadManifest((courier: courier, page: page));

  @override
  Future<Result<Shipment, ShipmentFailure>> assign({
    required ShipmentId id,
    required ActorId courier,
  }) => _advance(AssignToCourier(id: id, courier: courier));

  @override
  Future<Result<Shipment, ShipmentFailure>> loadOnto({
    required ShipmentId id,
    required ActorId courier,
  }) => _advance(LoadOntoVehicle(id: id, courier: courier));

  @override
  Future<Result<Shipment, ShipmentFailure>> startDelivery({
    required ShipmentId id,
    required ActorId courier,
  }) => _advance(StartDelivery(id: id, courier: courier));

  @override
  Future<Result<Shipment, ShipmentFailure>> completeDelivery({
    required ShipmentId id,
    required String proofReference,
  }) => _advance(CompleteDelivery(id: id, proofReference: proofReference));

  @override
  Future<Result<Shipment, ShipmentFailure>> failDelivery({
    required ShipmentId id,
    required String reason,
  }) => _advance(FailDelivery(id: id, reason: reason));

  @override
  Future<Result<Shipment, ShipmentFailure>> returnToDepot(ShipmentId id) =>
      _advance(ReturnToDepot(id: id));

  /// Emits a shipment whenever one this device knows about changes.
  ///
  /// A broadcast stream, so that a courier's stop list and a detail screen can
  /// both listen. Nothing is emitted for a refused move: the shipment did not
  /// change, and a screen that redrew on it would flicker for no reason.
  @override
  Stream<Shipment> changes() => _changes.stream;

  /// Releases the change stream.
  ///
  /// Called by the composition root when the container is torn down. The
  /// coordinator owns the controller, so it is the only thing that can.
  Future<void> dispose() => _changes.close();

  Future<Result<Shipment, ShipmentFailure>> _advance(ShipmentMove move) async {
    final result = await _advanceShipment(move);
    if (result case Success(value: final shipment)) _changes.add(shipment);
    return result;
  }
}
