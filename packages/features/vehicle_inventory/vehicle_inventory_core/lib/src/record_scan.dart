import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// Which count, and which parcel.
final class RecordScanCommand {
  /// Creates the command.
  const RecordScanCommand({required this.count, required this.shipment});

  /// Which count.
  final LoadCountId count;

  /// Which parcel.
  final ShipmentId shipment;
}

/// Records one scan against an open count.
///
/// The entity decides what a scan means — idempotent, and an unexpected parcel
/// is recorded rather than refused. This use case reads, asks and writes, and
/// takes no clock: a scan does not carry a time of its own. What a courier
/// needs from the record afterwards is what was in the van, not the minute
/// each beep happened, and a per-scan timestamp would be a field nobody reads
/// and everybody has to store.
final class RecordScan
    implements
        UseCase<RecordScanCommand, Result<LoadCount, VehicleInventoryFailure>> {
  /// Creates the use case.
  const RecordScan({required this._store});

  final LoadCountStore _store;

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> call(
    RecordScanCommand command,
  ) async {
    final read = await _store.all();
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }

    final counts =
        (read as Success<List<LoadCount>, VehicleInventoryFailure>).value;
    final index = counts.indexWhere((count) => count.id == command.count);
    if (index < 0) {
      return Failed(CountMissing(command.count.value));
    }

    final scanned = counts[index].scan(command.shipment);
    if (scanned case Failed(:final failure)) {
      return Failed(failure);
    }

    final next = (scanned as Success<LoadCount, VehicleInventoryFailure>).value;
    // The scan was already there. Writing again would be a disk touch for
    // nothing, and a courier who scans the same label four times would produce
    // four writes.
    if (identical(next, counts[index])) {
      return Success(next);
    }

    final written = await _store.update(next);
    return switch (written) {
      Failed(:final failure) => Failed(failure),
      Success() => Success(next),
    };
  }
}
