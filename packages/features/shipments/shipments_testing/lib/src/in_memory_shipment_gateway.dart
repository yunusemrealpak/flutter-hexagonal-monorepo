import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

/// A `ShipmentGateway` that really keeps shipments, in a map.
///
/// A fake, not a mock. It stores what it is given, hands back what it stored,
/// and resolves barcodes against the same map — so a test written against it
/// exercises the caller's logic rather than a script of expected calls. That
/// is what makes it keep passing when the caller is refactored and start
/// failing when the caller is broken.
///
/// It passes `runShipmentGatewayContract`, and so does the REST adapter in
/// `shipments_infrastructure`. Running one suite against both is what stops
/// the two drifting apart behaviourally, which is the failure a hand-written
/// fake is otherwise guaranteed to produce eventually.
final class InMemoryShipmentGateway implements ShipmentGateway {
  final Map<String, Shipment> _byId = {};

  final List<ShipmentFailure> _queuedFailures = [];

  /// Makes the next call — whichever it is — return [failure].
  ///
  /// Failure is part of a port's contract, so the fake that stands in for that
  /// contract has to be able to produce it. Without this the failure branch of
  /// every caller stays untested, and those are the branches that run on a bad
  /// day.
  void failNextWith(ShipmentFailure failure) => _queuedFailures.add(failure);

  /// Puts a shipment in place without going through [save].
  ///
  /// For arranging a test, not for use by the code under test.
  void seed(Shipment shipment) => _byId[shipment.id.value] = shipment;

  /// Everything the gateway currently holds.
  List<Shipment> get stored => List.unmodifiable(_byId.values);

  @override
  Future<Result<Shipment, ShipmentFailure>> byId(ShipmentId id) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    final shipment = _byId[id.value];
    if (shipment == null) return Failed(ShipmentNotFound(id));
    return Success(shipment);
  }

  @override
  Future<Result<PageOf<ShipmentSummary>, ShipmentFailure>> manifestFor(
    String courierId,
    PageRequest page,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    // Sorted by identifier, because the port requires a stable total order and
    // a `Map`'s insertion order is only stable until somebody re-saves a row.
    // The cursor is the last identifier served — this fake's business, and
    // opaque to every caller.
    final all =
        _byId.values
            .where((shipment) => shipment.status.courier?.value == courierId)
            .map(_summarise)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    final start = page.after == null
        ? 0
        : all.indexWhere((row) => row.id == page.after!.value) + 1;
    final rows = all.skip(start).take(page.limit).toList();
    final served = start + rows.length;

    return Success(
      PageOf(
        items: rows,
        next: served < all.length ? PageCursor(rows.last.id) : null,
      ),
    );
  }

  @override
  Future<Result<Shipment, ShipmentFailure>> save(Shipment shipment) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    _byId[shipment.id.value] = shipment;
    return Success(shipment);
  }

  @override
  Future<Result<ShipmentId, ShipmentFailure>> resolve(Barcode barcode) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    for (final shipment in _byId.values) {
      if (shipment.barcode == barcode) return Success(shipment.id);
    }
    return Failed(BarcodeNotRecognised(barcode.value));
  }

  ShipmentFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);

  static ShipmentSummary _summarise(Shipment shipment) => ShipmentSummary(
    id: shipment.id.value,
    barcode: shipment.barcode.value,
    status: shipment.status,
    consigneeName: shipment.consignee.name,
    address: shipment.consignee.address.formatted,
  );
}
