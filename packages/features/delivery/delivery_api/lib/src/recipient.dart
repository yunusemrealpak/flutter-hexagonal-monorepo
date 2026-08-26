import 'package:core_kernel/core_kernel.dart';
import 'package:meta/meta.dart';

import 'delivery_failure.dart';

/// Who took the parcel, and what they are to the person it was addressed to.
///
/// Not shipments' `Consignee`. A consignee is who the parcel was *for* and it
/// is a fact about the shipment; a recipient is who was actually at the door
/// and it is a fact about the visit. Most of the time they are the same
/// person, and the times they are not — a neighbour, a concierge, a colleague
/// — are exactly the ones a delivery dispute turns on.
///
/// [relationship] is a plain string rather than an enum on purpose. The set is
/// open — every operation has its own list of who may sign for a parcel, and
/// an enum here would either be wrong for somebody or grow a `other(String)`
/// case that is the string with more ceremony.
@immutable
final class Recipient {
  const Recipient._({required this.name, required this.relationship});

  /// Reads a recipient, refusing one with no name.
  ///
  /// A hand-over with no name on it is not evidence of anything, which is the
  /// whole reason this type exists rather than a `String?` on the proof.
  static Result<Recipient, DeliveryFailure> named(
    String name, {
    String relationship = 'self',
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedDeliveryValue(field: 'recipient.name', reason: 'is empty'),
      );
    }

    final role = relationship.trim();
    if (role.isEmpty) {
      return const Failed(
        MalformedDeliveryValue(
          field: 'recipient.relationship',
          reason: 'is empty',
        ),
      );
    }

    return Success(Recipient._(name: trimmed, relationship: role));
  }

  /// What they gave as their name.
  final String name;

  /// What they are to the consignee — `self`, `neighbour`, `reception`.
  final String relationship;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipient &&
          other.name == name &&
          other.relationship == relationship;

  @override
  int get hashCode => Object.hash(name, relationship);

  @override
  String toString() => 'Recipient($name, $relationship)';
}
