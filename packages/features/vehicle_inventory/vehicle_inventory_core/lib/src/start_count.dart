import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// Whose van, and which way the parcels are going.
final class StartCountCommand {
  /// Creates the command.
  const StartCountCommand({required this.courier, required this.direction});

  /// Whose van.
  final ActorId courier;

  /// Which way.
  final LoadDirection direction;
}

/// Opens a count against the manifest the depot says is right.
///
/// **This is where the raw identifiers become typed ones.** `ManifestSource`
/// answers with strings so that its adapters need not see `shipments_api`;
/// this use case parses them, and a manifest carrying something that is not a
/// shipment identifier fails here rather than being silently dropped. A
/// dropped entry would be a parcel nobody counts and nobody misses.
final class StartCount
    implements
        UseCase<StartCountCommand, Result<LoadCount, VehicleInventoryFailure>> {
  /// Creates the use case.
  const StartCount({
    required this._manifests,
    required this._store,
    required this._clock,
    required this._ids,
  });

  final ManifestSource _manifests;
  final LoadCountStore _store;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> call(
    StartCountCommand command,
  ) async {
    final manifest = await _manifests.manifestFor(command.courier.value);
    if (manifest case Failed(:final failure)) {
      return Failed(failure);
    }

    final parsed = _shipments(
      (manifest as Success<List<String>, VehicleInventoryFailure>).value,
    );
    if (parsed case Failed(:final failure)) {
      return Failed(failure);
    }

    final built = LoadCountId.parse(_ids.newId()).flatMap(
      (id) => LoadCount.opened(
        id: id,
        courier: command.courier,
        direction: command.direction,
        manifest:
            (parsed as Success<Set<ShipmentId>, VehicleInventoryFailure>).value,
        startedAt: _clock.now(),
      ),
    );
    if (built case Failed(:final failure)) {
      return Failed(failure);
    }

    final count = (built as Success<LoadCount, VehicleInventoryFailure>).value;
    final opened = await _store.open(count);

    return switch (opened) {
      Failed(:final failure) => Failed(failure),
      Success() => Success(count),
    };
  }

  Result<Set<ShipmentId>, VehicleInventoryFailure> _shipments(
    List<String> raw,
  ) {
    final parsed = <ShipmentId>{};
    for (final value in raw) {
      final id = ShipmentId.parse(value);
      if (id case Failed()) {
        return Failed(
          MalformedCount(
            field: 'manifest',
            reason: '"$value" is not a shipment identifier',
          ),
        );
      }
      parsed.add((id as Success<ShipmentId, ShipmentFailure>).value);
    }
    return Success(parsed);
  }
}
