import 'package:core_kernel/core_kernel.dart';

import '../../failures/delivery_failure.dart';
import '../../values/proof_of_delivery.dart';
import '../../values/proof_reference.dart';

/// Where the evidence goes.
///
/// A driven port with two implementations that differ in the one way that
/// matters: `LocalEncryptedProofStore` keeps the bytes on the courier's device
/// and `RemoteProofStore` posts them to a server. `app_courier` binds the
/// first because a signature captured in a basement still has to be kept;
/// `app_dispatcher` binds the second because an operator's machine has no
/// business holding a thousand couriers' photographs. Both pass one contract
/// kit, and no use case changes between them.
///
/// [put] takes the whole proof and returns only a handle. That asymmetry is
/// the feature: the bytes go in, a short string comes out, and the string is
/// the only thing the rest of the product ever sees.
abstract interface class ProofStorePort {
  /// Stores [proof] and returns the handle it can be found by.
  Future<Result<ProofReference, DeliveryFailure>> put(ProofOfDelivery proof);

  /// Reads back what was stored under [reference].
  ///
  /// The reference arrives raw, like every driven port's identifier: an
  /// adapter has to be able to write the signature down without seeing the
  /// value objects of a feature it does not belong to. Here that adapter is
  /// delivery's own, so the constraint costs nothing — and applying it anyway
  /// keeps one rule instead of two.
  Future<Result<ProofOfDelivery, DeliveryFailure>> read(String reference);
}
