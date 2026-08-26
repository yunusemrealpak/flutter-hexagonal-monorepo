import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';

/// A `DeliveryGateway` that really records what it was given.
///
/// Attempts accumulate per shipment, oldest first, which is the behaviour the
/// port promises: "nobody home on Tuesday, delivered on Wednesday" is two rows
/// and a fake that kept only the latest would let a caller's bug through.
final class FakeDeliveryGateway implements DeliveryGateway {
  final Map<String, List<DeliveryAttempt>> _byShipment = {};
  final List<DeliveryFailure> _queuedFailures = [];

  /// Every attempt this gateway was asked to publish, in order.
  final List<DeliveryAttempt> submitted = [];

  /// Makes the next call return [failure].
  void failNextWith(DeliveryFailure failure) => _queuedFailures.add(failure);

  @override
  Future<Result<DeliveryAttempt, DeliveryFailure>> submit(
    DeliveryAttempt attempt,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    submitted.add(attempt);
    // Replace by identifier rather than append. A resent attempt is the same
    // visit — that is what the identifier is for — and a gateway that stacked
    // copies would make a retry look like a second delivery.
    final rows = _byShipment.putIfAbsent(attempt.shipment.value, () => []);
    final at = rows.indexWhere((row) => row.id == attempt.id);
    if (at < 0) {
      rows.add(attempt);
    } else {
      rows[at] = attempt;
    }

    return Success(attempt);
  }

  @override
  Future<Result<List<DeliveryAttempt>, DeliveryFailure>> attemptsFor(
    String shipmentId,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    // An empty list, not a failure. A parcel nobody has visited yet is the
    // ordinary case, and a screen that showed an error for it would send
    // somebody looking for a problem that does not exist.
    return Success(List.unmodifiable(_byShipment[shipmentId] ?? const []));
  }

  DeliveryFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
