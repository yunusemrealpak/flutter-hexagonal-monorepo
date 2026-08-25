import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

/// A fake, not a mock: it really stores what it is given and really returns
/// it.
///
/// A test written against this exercises the caller's logic rather than a
/// script of expected calls, which is why it keeps passing when the caller is
/// refactored and starts failing when the caller is broken.
///
/// Failure is part of the port's contract, so the fake can produce it —
/// otherwise every caller's failure branch stays untested.
final class FakeShipmentsRepository implements ShipmentsRepository {
  final Map<String, String> _records = {};
  final List<ShipmentsFailure> _queuedFailures = [];

  /// Makes [id] resolve to [value].
  void give(String id, String value) => _records[id] = value;

  /// Makes the next call fail with [failure], whatever is stored.
  ///
  /// A queue rather than a single slot, so a test can line up two failures
  /// and assert on a retry.
  void failNextWith(ShipmentsFailure failure) => _queuedFailures.add(failure);

  @override
  Future<Result<String, ShipmentsFailure>> byId(String id) async {
    if (_queuedFailures.isNotEmpty) {
      return Failed<String, ShipmentsFailure>(_queuedFailures.removeAt(0));
    }
    final found = _records[id];
    return found == null
        ? Failed<String, ShipmentsFailure>(ShipmentsNotFound(id))
        : Success<String, ShipmentsFailure>(found);
  }
}
