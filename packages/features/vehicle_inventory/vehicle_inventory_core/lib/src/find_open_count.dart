import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';
import 'package:vehicle_inventory_api/vehicle_inventory_api.dart';

/// Finds the count a courier is in the middle of, if there is one.
///
/// Answers `null` rather than a failure when there is none: a courier who has
/// not started counting is in an ordinary state.
///
/// The newest open count wins when there is more than one. There should not
/// be — the app opens one at a time — but a phone that was killed mid-count
/// leaves one behind, and handing a courier the older of two would put them
/// back in this morning's count in the afternoon.
final class FindOpenCount
    implements UseCase<ActorId, Result<LoadCount?, VehicleInventoryFailure>> {
  /// Creates the use case.
  const FindOpenCount({required this._store});

  final LoadCountStore _store;

  @override
  Future<Result<LoadCount?, VehicleInventoryFailure>> call(
    ActorId input,
  ) async {
    final read = await _store.all();

    return read.map((counts) {
      final open =
          counts
              .where((count) => count.isOpen && count.courier == input)
              .toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return open.isEmpty ? null : open.first;
    });
  }
}
