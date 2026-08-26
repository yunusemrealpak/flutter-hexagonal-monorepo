import 'package:core_kernel/core_kernel.dart';

import 'delivery_failure.dart';

/// The handle a stored proof is known by, everywhere outside `delivery`.
///
/// **This type is why a signature bitmap never leaves this feature.**
/// `ShipmentStatus.deliveredToConsignee` carries a `proofReference`,
/// `DeliveryCompleted` carries one, and the sync command that eventually
/// reaches the server carries one — a short string in every case. The bytes
/// stay behind whichever `ProofStorePort` the app bound, which is what lets
/// `app_courier` keep them encrypted on the device and `app_dispatcher` keep
/// them on a server without anything else in the product noticing.
///
/// It crosses feature boundaries as a plain `String` rather than as this type,
/// for the same reason a driven port takes a raw identifier: `shipments_api`
/// may not name a delivery type, and a reference it could not read would be a
/// reference it could not store.
final class ProofReference extends ValueObject<String> {
  const ProofReference._(super.value);

  /// Reads a reference from [raw].
  static Result<ProofReference, DeliveryFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedDeliveryValue(field: 'proofReference', reason: 'is empty'),
      );
    }
    return Success(ProofReference._(trimmed));
  }
}
