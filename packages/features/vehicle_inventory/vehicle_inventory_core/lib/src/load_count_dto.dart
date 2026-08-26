import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// The stored shape of one count.
///
/// The two sets are stored as lists, because JSON has no set. Reading them
/// back into sets is what makes the idempotence of a scan survive a restart:
/// a list that came back with a duplicate in it would otherwise become a count
/// that never reconciles.
final class LoadCountDto {
  /// Creates the DTO.
  const LoadCountDto({
    required this.id,
    required this.courier,
    required this.direction,
    required this.manifest,
    required this.scanned,
    required this.startedAt,
    required this.closedAt,
  });

  /// Builds the DTO that carries [count].
  factory LoadCountDto.fromDomain(LoadCount count) => LoadCountDto(
    id: count.id.value,
    courier: count.courier.value,
    direction: count.direction.name,
    manifest: [for (final id in count.manifest) id.value],
    scanned: [for (final id in count.scanned) id.value],
    startedAt: count.startedAt.toIso8601String(),
    closedAt: count.closedAt?.toIso8601String(),
  );

  /// Reads one from a decoded JSON object, or `null` when the shape is wrong.
  static LoadCountDto? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final courier = json['courier'];
    final direction = json['direction'];
    final startedAt = json['startedAt'];
    final closedAt = json['closedAt'];
    final manifest = _identifiers(json['manifest']);
    final scanned = _identifiers(json['scanned']);
    if (id is! String ||
        courier is! String ||
        direction is! String ||
        startedAt is! String ||
        (closedAt != null && closedAt is! String) ||
        manifest == null ||
        scanned == null) {
      return null;
    }

    return LoadCountDto(
      id: id,
      courier: courier,
      direction: direction,
      manifest: manifest,
      scanned: scanned,
      startedAt: startedAt,
      closedAt: closedAt as String?,
    );
  }

  /// Reads every stored count from the text a key-value store gave back.
  static List<LoadCountDto>? decodeAll(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return null;
      }
      final rows = <LoadCountDto>[];
      for (final element in decoded) {
        if (element is! Map<String, Object?>) {
          return null;
        }
        final dto = fromJson(element);
        if (dto == null) {
          return null;
        }
        rows.add(dto);
      }
      return rows;
    } on FormatException {
      return null;
    }
  }

  /// The text to store for [rows].
  static String encodeAll(List<LoadCountDto> rows) =>
      jsonEncode([for (final row in rows) row._toJson()]);

  /// The identifier, as stored.
  final String id;

  /// Whose van, as stored.
  final String courier;

  /// Which way the parcels were going, as stored.
  final String direction;

  /// What the depot expected.
  final List<String> manifest;

  /// What was scanned.
  final List<String> scanned;

  /// When the count started, ISO 8601 in UTC.
  final String startedAt;

  /// When it closed, or `null`.
  final String? closedAt;

  /// The count this DTO carries, or the first failure that stopped it.
  Result<LoadCount, VehicleInventoryFailure> toDomain() {
    final started = DateTime.tryParse(startedAt);
    if (started == null) {
      return Failed(
        MalformedCount(
          field: 'startedAt',
          reason: '"$startedAt" is not an instant',
        ),
      );
    }
    final closing = closedAt;
    if (closing != null && DateTime.tryParse(closing) == null) {
      return Failed(
        MalformedCount(
          field: 'closedAt',
          reason: '"$closing" is not an instant',
        ),
      );
    }

    final expected = _shipments(manifest, 'manifest');
    if (expected case Failed(:final failure)) {
      return Failed(failure);
    }
    final counted = _shipments(scanned, 'scanned');
    if (counted case Failed(:final failure)) {
      return Failed(failure);
    }

    return LoadCountId.parse(id).flatMap(
      (identifier) => _courier().flatMap(
        (actor) => LoadDirection.parse(direction).flatMap(
          (way) => LoadCount.stored(
            id: identifier,
            courier: actor,
            direction: way,
            manifest:
                (expected as Success<Set<ShipmentId>, VehicleInventoryFailure>)
                    .value,
            scanned:
                (counted as Success<Set<ShipmentId>, VehicleInventoryFailure>)
                    .value,
            startedAt: started,
            closedAt: closing == null ? null : DateTime.parse(closing),
          ),
        ),
      ),
    );
  }

  Result<ActorId, VehicleInventoryFailure> _courier() =>
      ActorId.parse(courier).mapFailure(
        (_) => const MalformedCount(
          field: 'courier',
          reason: 'it is not an actor identifier',
        ),
      );

  static Result<Set<ShipmentId>, VehicleInventoryFailure> _shipments(
    List<String> raw,
    String field,
  ) {
    final parsed = <ShipmentId>{};
    for (final value in raw) {
      final id = ShipmentId.parse(value);
      if (id case Failed()) {
        return Failed(
          MalformedCount(
            field: field,
            reason: '"$value" is not a shipment identifier',
          ),
        );
      }
      parsed.add((id as Success<ShipmentId, ShipmentFailure>).value);
    }
    return Success(parsed);
  }

  static List<String>? _identifiers(Object? value) {
    if (value is! List) {
      return null;
    }
    final identifiers = <String>[];
    for (final element in value) {
      if (element is! String) {
        return null;
      }
      identifiers.add(element);
    }
    return identifiers;
  }

  Map<String, Object?> _toJson() => {
    'id': id,
    'courier': courier,
    'direction': direction,
    'manifest': manifest,
    'scanned': scanned,
    'startedAt': startedAt,
    'closedAt': closedAt,
  };
}
