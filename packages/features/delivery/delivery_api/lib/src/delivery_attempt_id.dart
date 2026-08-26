import 'package:core_kernel/core_kernel.dart';

import 'delivery_failure.dart';

/// Identifies one visit to one address.
///
/// One shipment can have several: a courier who found nobody home on Tuesday
/// and delivered on Wednesday made two attempts, and both are worth keeping —
/// the first is what an operation is asked about when a customer complains.
/// An identifier that was the shipment's could not express that.
///
/// It also carries the de-duplication. The identifier is minted once, from the
/// `IdGenerator` port, at the moment a courier starts an attempt; every retry
/// of the same intention — the queued write, the resend after a timeout —
/// carries it, so the server can recognise the second copy of one delivery.
final class DeliveryAttemptId extends ValueObject<String> {
  const DeliveryAttemptId._(super.value);

  /// Reads an attempt identifier from [raw].
  static Result<DeliveryAttemptId, DeliveryFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedDeliveryValue(field: 'deliveryAttemptId', reason: 'is empty'),
      );
    }
    return Success(DeliveryAttemptId._(trimmed));
  }
}
