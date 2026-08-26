import 'dart:convert';

import 'package:delivery_api/delivery_api.dart';
import 'package:sync_api/sync_api.dart';

/// A completed delivery, on its way to the server through the outbox.
///
/// **This is delivery's half of scenario 3.** `sync` carries this write and
/// never learns what it is: it stores a routing key and a string, hands both
/// to whatever transport handler the composition root registered for that key,
/// and could not decode the payload if it wanted to. The dependency arrow runs
/// from here to `sync_api` and never the other way.
///
/// It lives in `_application` rather than in `_api` or `_infrastructure`, and
/// both halves of that matter. Not `_api`, because a serialised payload is a
/// wire concern and rule I4 keeps those out of a contract package. Not
/// `_infrastructure`, because this is a *value* — nothing here touches the
/// outside world — and putting it there would mean `CompleteWithProof` could
/// not build one.
///
/// **The payload carries the proof's reference, never the proof.** A signature
/// bitmap in an outbox row is a signature bitmap in a `TEXT` column, base64'd,
/// on a device with limited storage and a queue that may hold a day's work.
/// The bytes went to a `ProofStorePort` before this command was built, and the
/// handle is what travels.
///
/// [type] is stable across releases. Changing it strands every entry already
/// queued on a device that has not drained, because the app's registry will no
/// longer have a handler for the old string.
final class CompleteDeliveryCommand implements SyncCommand {
  /// Describes [attempt], which must be a completed one.
  const CompleteDeliveryCommand(this.attempt);

  /// The settled attempt this command is about.
  final DeliveryAttempt attempt;

  @override
  String get type => 'delivery.completeAttempt';

  @override
  String get payload => jsonEncode({
    // The attempt's identifier is what the server de-duplicates on. Every
    // retry of one intention carries it, which is what makes a resend after a
    // timeout a second copy rather than a second delivery.
    'attemptId': attempt.id.value,
    'shipmentId': attempt.shipment.value,
    'courierId': attempt.courier.value,
    'grade': attempt.grade.name,
    'startedAt': attempt.startedAt.toIso8601String(),
    'settledAt': attempt.settledAt?.toIso8601String(),
    'proofReference': attempt.proofReference?.value,
    if (attempt.outcome case AttemptCompleted(:final proof)) ...{
      'recipient': {
        'name': proof.recipient.name,
        'relationship': proof.recipient.relationship,
      },
      // Which kinds, not the evidence itself. The server can tell from this
      // whether a high-value parcel was closed the way its policy demands,
      // without the bytes ever leaving the store they were put in.
      'evidence': [
        for (final kind in proof.carries) kind.name,
      ]..sort(),
    },
  });

  @override
  String toString() => 'CompleteDeliveryCommand(${attempt.id.value})';
}
