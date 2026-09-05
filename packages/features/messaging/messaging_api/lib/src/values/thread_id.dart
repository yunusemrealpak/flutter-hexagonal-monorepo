import 'package:core_kernel/core_kernel.dart';
import 'package:shipments_api/shipments_api.dart';

import '../failures/messaging_failure.dart';

/// Identifies one conversation.
///
/// **Derived, unlike `MessageId`.** A thread about a parcel is
/// `shipment:SHP-42` and a courier's direct line to the operation is
/// `courier:courier-7`, and the two devices talking have to agree on the
/// string without asking anybody. That is the same reason `SettlementId` is
/// derived in payments while `IdempotencyKey` is not: an identifier two
/// parties must compute independently cannot be minted.
final class ThreadId extends ValueObject<String> {
  const ThreadId._(super.value);

  /// The thread about [shipment].
  ///
  /// A constructor rather than a parse, because there is nothing to validate:
  /// a `ShipmentId` is already a valid identifier, and the prefix is this
  /// type's own.
  factory ThreadId.aboutShipment(ShipmentId shipment) =>
      ThreadId._('shipment:${shipment.value}');

  /// The direct thread with the actor identified by [actorId].
  ///
  /// Takes the raw identifier rather than an `ActorId`, because the callers
  /// that need it most are adapters rebuilding a stored thread — and an
  /// adapter that had to see `identity_api` to name a thread would be one this
  /// feature could not split later.
  factory ThreadId.withActor(String actorId) => ThreadId._('courier:$actorId');

  /// Reads a thread identifier from [raw].
  static Result<ThreadId, MessagingFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('shipment:') && !trimmed.startsWith('courier:')) {
      return Failed(
        MalformedMessage(
          field: 'threadId',
          reason: '"$trimmed" names neither a shipment nor a courier',
        ),
      );
    }
    if (trimmed.split(':').last.isEmpty) {
      return const Failed(
        MalformedMessage(field: 'threadId', reason: 'it names nothing'),
      );
    }
    return Success(ThreadId._(trimmed));
  }

  /// Whether this thread is about a parcel.
  bool get isAboutShipment => value.startsWith('shipment:');
}
