import 'dart:convert';

import 'package:payments_api/payments_api.dart';
import 'package:sync_api/sync_api.dart';

/// A cash collection, on its way to the server through the outbox.
///
/// **Payments' half of scenario 3**, and it is queued in exactly one case:
/// cash, when the gateway could not be reached. That restriction is the
/// interesting part of this file and it is enforced in `CollectOnDelivery`
/// rather than here — see that use case for why a card may not take the same
/// route.
///
/// The payload carries the idempotency key, which is what makes the queue safe
/// to retry: `sync` will resend this entry until the server acknowledges it,
/// and every copy names the same intention.
///
/// [type] is stable across releases. Changing it strands every entry already
/// queued on a device that has not drained, because the app's registry will no
/// longer have a handler for the old string.
final class CollectPaymentCommand implements SyncCommand {
  /// Describes [attempt], which must be a taken one.
  const CollectPaymentCommand(this.attempt);

  /// The attempt this command is about.
  final PaymentAttempt attempt;

  @override
  String get type => 'payments.collect';

  @override
  String get payload => jsonEncode({
    'idempotencyKey': attempt.id.value,
    'shipmentId': attempt.request.shipment.value,
    'courierId': attempt.request.courier.value,
    'minorUnits': attempt.amount.minorUnits,
    'currency': attempt.amount.currency.code,
    'method': switch (attempt.request.method) {
      Cash() => 'cash',
      Card() => 'card',
      Transfer() => 'transfer',
    },
    // Only the last four digits ever leave this feature, and only because a
    // customer recognises them on a receipt. A payments feature that queued a
    // full card number would put every device holding an outbox inside a
    // compliance scope nobody signed up for.
    if (attempt.request.method case Card(:final last4)) 'last4': last4,
    if (attempt.request.method case Transfer(:final reference))
      'transferReference': reference,
    'takenAt': switch (attempt.outcome) {
      PaymentTaken(:final at) => at.toIso8601String(),
      _ => null,
    },
  });

  @override
  String toString() => 'CollectPaymentCommand(${attempt.id.value})';
}
