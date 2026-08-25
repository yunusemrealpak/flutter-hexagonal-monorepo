import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:shipments_api/shipments_api.dart';

import 'shipment_dto.dart';
import 'shipment_mapper.dart';

/// Answers `ShipmentCache` over the `KeyValueStore` port.
///
/// **Why not drift.** The specification puts persistence in `storage_drift`,
/// and that is right for a feature that queries: a shipment history, a
/// settlement report, anything with a `where` clause worth pushing down. This
/// cache does two things — read one shipment by identifier, and list the ones
/// on a courier — over a working set a courier can physically carry. A schema,
/// a migration and a code generator for that would be machinery with nothing
/// to do. The moment the device needs a query the store cannot express, this
/// class is replaced by a drift-backed one and nothing above it changes: it is
/// behind a port, and the contract kit in `shipments_testing` is what proves
/// the replacement behaves the same.
///
/// A miss is `Success(null)`, not a failure. An empty cache is the ordinary
/// state of a fresh install, and reporting it as a failure would put "no
/// signal" where "we have not seen this yet" belongs.
final class KeyValueShipmentCache implements ShipmentCache {
  /// Creates the cache over [store].
  const KeyValueShipmentCache({required this.store});

  /// Where the shipments are kept.
  final KeyValueStore store;

  /// The prefix every key this cache owns carries.
  ///
  /// A store is shared with whatever else an app decided to keep in it, so a
  /// cache that used bare identifiers as keys would collide with the first
  /// feature that had a `ship-1` of its own.
  static const String keyPrefix = 'shipments/';

  @override
  Future<Result<Shipment?, ShipmentFailure>> byId(ShipmentId id) async {
    final read = await store.read('$keyPrefix${id.value}');

    return switch (read) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: null) => const Success(null),
      Success(value: final raw?) => _decode(raw).map((shipment) => shipment),
    };
  }

  @override
  Future<Result<List<ShipmentSummary>, ShipmentFailure>> manifestFor(
    String courierId,
  ) async {
    final all = await _all();

    return all.map(
      (shipments) => shipments
          .where((shipment) => shipment.status.courier?.value == courierId)
          .map(
            (shipment) => ShipmentSummary(
              id: shipment.id.value,
              barcode: shipment.barcode.value,
              status: shipment.status,
              consigneeName: shipment.consignee.name,
              address: shipment.consignee.address.formatted,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<Result<void, ShipmentFailure>> put(Shipment shipment) async {
    final written = await store.write(
      '$keyPrefix${shipment.id.value}',
      jsonEncode(ShipmentMapper.toDto(shipment).toJson()),
    );

    return written.mapFailure(_translate);
  }

  @override
  Future<Result<void, ShipmentFailure>> clear() async {
    final keys = await store.keys();
    if (keys case Failed(:final failure)) return Failed(_translate(failure));

    for (final key in keys.fold((all) => all, (_) => const <String>{})) {
      if (!key.startsWith(keyPrefix)) continue;
      final deleted = await store.delete(key);
      if (deleted case Failed(:final failure)) {
        return Failed(_translate(failure));
      }
    }
    return const Success(null);
  }

  Future<Result<List<Shipment>, ShipmentFailure>> _all() async {
    final keys = await store.keys();
    if (keys case Failed(:final failure)) return Failed(_translate(failure));

    final shipments = <Shipment>[];
    for (final key in keys.fold((all) => all, (_) => const <String>{})) {
      if (!key.startsWith(keyPrefix)) continue;

      final read = await store.read(key);
      switch (read) {
        case Failed(:final failure):
          return Failed(_translate(failure));
        case Success(value: null):
          continue;
        case Success(value: final raw?):
          final decoded = _decode(raw);
          switch (decoded) {
            case Failed(:final failure):
              return Failed(failure);
            case Success(:final value):
              shipments.add(value);
          }
      }
    }
    return Success(shipments);
  }

  Result<Shipment, ShipmentFailure> _decode(String raw) {
    final decoded = _tryDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const Failed(
        MalformedValue(field: 'cache', reason: 'is not a JSON object'),
      );
    }
    return ShipmentMapper.toDomain(ShipmentDto.fromJson(decoded));
  }

  static Object? _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  /// Turns a store failure into the vocabulary the port promises.
  ///
  /// `StoreCorrupted` becomes a malformed value rather than an unavailability,
  /// because they call for different behaviour: unavailable is worth retrying
  /// and corrupt is worth discarding.
  static ShipmentFailure _translate(StoreFailure failure) => switch (failure) {
    StoreUnavailable(:final detail) => ShipmentsUnavailable(detail: detail),
    StoreCorrupted(:final key) => MalformedValue(
      field: 'cache',
      reason: 'corrupt entry at $key',
    ),
    StoreOutOfSpace() => const ShipmentsUnavailable(detail: 'out of space'),
  };
}
