import 'package:core_kernel/core_kernel.dart';
import 'package:delivery_api/delivery_api.dart';

/// A `ProofStorePort` that really keeps proofs, in a map.
///
/// It is not a script of expected calls: what goes in comes back out, under a
/// reference it minted, and reading an unknown one really fails. That is what
/// lets a test written against this fake exercise the caller's logic rather
/// than the fake's.
///
/// It is also a product adapter. `app_harness` binds it — scenario 5's table
/// says so — which is why it lives in a package apps may depend on rather than
/// in somebody's `test/` directory.
///
/// References are minted from a counter rather than from `Random` or `Uuid`.
/// Rule A2 and A3 forbid the ambient versions everywhere outside `apps/` and
/// `tooling/`, and a counter is better here anyway: `proof-1` in a failure
/// message says which call produced it.
final class FakeProofStore implements ProofStorePort {
  final Map<String, ProofOfDelivery> _byReference = {};
  final List<DeliveryFailure> _queuedFailures = [];

  var _minted = 0;

  /// Makes the next call return [failure].
  void failNextWith(DeliveryFailure failure) => _queuedFailures.add(failure);

  /// Every reference this store has handed out, in order.
  List<String> get references => List.unmodifiable(_byReference.keys);

  @override
  Future<Result<ProofReference, DeliveryFailure>> put(
    ProofOfDelivery proof,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    _minted++;
    final raw = 'proof-$_minted';
    _byReference[raw] = proof;
    return ProofReference.parse(raw);
  }

  @override
  Future<Result<ProofOfDelivery, DeliveryFailure>> read(
    String reference,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Failed(failure);

    final proof = _byReference[reference];
    if (proof == null) return Failed(ProofNotFound(reference));
    return Success(proof);
  }

  DeliveryFailure? _takeFailure() =>
      _queuedFailures.isEmpty ? null : _queuedFailures.removeAt(0);
}
