import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

import 'load_count_dto.dart';

/// Keeps counts in a key-value store.
///
/// The infrastructure half of this package, alongside the two manifest
/// sources. It imports no use case, and no use case imports it.
final class KeyValueLoadCountStore implements LoadCountStore {
  /// Creates the adapter over the store it keeps counts in.
  const KeyValueLoadCountStore({required this._store});

  final KeyValueStore _store;

  /// The key this adapter writes.
  static const key = 'vehicle_inventory.counts';

  @override
  Future<Result<List<LoadCount>, VehicleInventoryFailure>> all() => _read();

  @override
  Future<Result<void, VehicleInventoryFailure>> open(LoadCount count) async {
    final read = await _read();
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }
    final stored =
        (read as Success<List<LoadCount>, VehicleInventoryFailure>).value;

    if (stored.any((held) => held.id == count.id)) {
      return const Success(null);
    }
    return _write([count, ...stored]);
  }

  @override
  Future<Result<void, VehicleInventoryFailure>> update(LoadCount count) async {
    final read = await _read();
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }
    final stored =
        (read as Success<List<LoadCount>, VehicleInventoryFailure>).value;

    final index = stored.indexWhere((held) => held.id == count.id);
    if (index < 0) {
      return Failed(CountMissing(count.id.value));
    }
    return _write([...stored]..[index] = count);
  }

  Future<Result<List<LoadCount>, VehicleInventoryFailure>> _read() async {
    final raw = await _store.read(key);

    return switch (raw) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success(value: null) => const Success([]),
      Success(value: final text?) => switch (LoadCountDto.decodeAll(text)) {
        null => const Failed(
          CountUnavailable(detail: 'the stored counts could not be decoded'),
        ),
        final rows => _toDomain(rows),
      },
    };
  }

  Result<List<LoadCount>, VehicleInventoryFailure> _toDomain(
    List<LoadCountDto> rows,
  ) {
    final counts = <LoadCount>[];
    for (final row in rows) {
      final count = row.toDomain();
      if (count case Failed(:final failure)) {
        return Failed(failure);
      }
      counts.add(
        (count as Success<LoadCount, VehicleInventoryFailure>).value,
      );
    }
    return Success(counts);
  }

  Future<Result<void, VehicleInventoryFailure>> _write(
    List<LoadCount> counts,
  ) async {
    final written = await _store.write(
      key,
      LoadCountDto.encodeAll([
        for (final count in counts) LoadCountDto.fromDomain(count),
      ]),
    );

    return switch (written) {
      Failed(:final failure) => Failed(_translate(failure)),
      Success() => const Success(null),
    };
  }

  VehicleInventoryFailure _translate(StoreFailure failure) => switch (failure) {
    StoreCorrupted(:final key) => CountUnavailable(detail: 'corrupt at $key'),
    StoreUnavailable(:final detail) => CountUnavailable(detail: detail),
    StoreOutOfSpace() => const CountUnavailable(
      detail: 'no room to store the count',
    ),
  };
}
