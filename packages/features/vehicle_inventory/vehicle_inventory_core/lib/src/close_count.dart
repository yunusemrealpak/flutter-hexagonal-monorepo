import 'package:core_kernel/core_kernel.dart';
import 'package:core_ports/core_ports.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// Closes a count, whether or not the van matches the paperwork.
///
/// It logs a count that closed with a discrepancy. Nobody is stopped and
/// nothing is refused — that is `LoadCount`'s decision and the right one — but
/// a missing parcel that leaves no trace anywhere except a record somebody has
/// to go looking for is a missing parcel nobody looks for.
final class CloseCount
    implements
        UseCase<LoadCountId, Result<LoadCount, VehicleInventoryFailure>> {
  /// Creates the use case.
  const CloseCount({
    required this._store,
    required this._clock,
    required this._logger,
  });

  final LoadCountStore _store;
  final Clock _clock;
  final Logger _logger;

  @override
  Future<Result<LoadCount, VehicleInventoryFailure>> call(
    LoadCountId input,
  ) async {
    final read = await _store.all();
    if (read case Failed(:final failure)) {
      return Failed(failure);
    }

    final counts =
        (read as Success<List<LoadCount>, VehicleInventoryFailure>).value;
    final index = counts.indexWhere((count) => count.id == input);
    if (index < 0) {
      return Failed(CountMissing(input.value));
    }

    final closed = counts[index].closedAtInstant(_clock.now());
    if (closed case Failed(:final failure)) {
      return Failed(failure);
    }

    final next = (closed as Success<LoadCount, VehicleInventoryFailure>).value;
    final written = await _store.update(next);
    if (written case Failed(:final failure)) {
      return Failed(failure);
    }

    if (!next.isReconciled) {
      _logger.log(
        LogLevel.warning,
        'count ${next.id.value} closed with ${next.missing.length} missing '
        'and ${next.unexpected.length} unexpected',
      );
    }
    return Success(next);
  }
}
