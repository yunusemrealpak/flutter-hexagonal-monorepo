import 'package:core_kernel/core_kernel.dart';
import 'package:payments_api/payments_api.dart';

/// A `SettlementStore` that really keeps days, in a map.
///
/// One settlement per identifier, replaced rather than accumulated — the same
/// rule the port states, honoured here so that a test written against this
/// fake exercises the caller's logic rather than a script of expected calls.
///
/// It is also a product adapter: `app_dispatcher` binds it, because an
/// operator reads a courier's day from a server every time the screen opens
/// and a database file on a desktop buys nothing.
final class InMemorySettlementStore implements SettlementStore {
  final Map<String, Settlement> _byId = {};
  final List<PaymentsFailure> _queuedFailures = [];

  /// Every settlement the store currently holds.
  List<Settlement> get stored => List.unmodifiable(_byId.values);

  /// Makes the next call return [failure].
  void failNextWith(PaymentsFailure failure) => _queuedFailures.add(failure);

  /// Puts [settlement] in the store without going through `save`.
  void seed(Settlement settlement) => _byId[settlement.id.value] = settlement;

  @override
  Future<Result<Settlement?, PaymentsFailure>> read(String settlementId) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    // A missing day is a successful read of nothing. A courier's first
    // collection of the morning arrives before anything has been written, and
    // reporting that as an error would make every shift start with one.
    return Success(_byId[settlementId]);
  }

  @override
  Future<Result<Settlement, PaymentsFailure>> save(
    Settlement settlement,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    _byId[settlement.id.value] = settlement;
    return Success(settlement);
  }

  PaymentsFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
