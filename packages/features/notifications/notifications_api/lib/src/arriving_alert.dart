import 'notification_kind.dart';

/// An alert as it reached the device, before it has an identity in an inbox.
///
/// Not an `InboxEntry`: it has no identifier of its own until the adapter has
/// decided whether the sender gave one, and it has no read mark because
/// nothing has been read. Keeping the two types apart is what stops a caller
/// constructing an entry that arrived already read.
final class ArrivingAlert {
  /// Records an alert that has just arrived.
  const ArrivingAlert({
    required this.externalId,
    required this.kind,
    required this.subject,
    required this.arguments,
  });

  /// The sender's identifier for it, or `null` when it sent none.
  ///
  /// What makes the second copy of an at-least-once delivery recognisable. A
  /// sender that gave none leaves the receiving side to mint one, and two
  /// copies of that alert are then genuinely indistinguishable.
  final String? externalId;

  /// What the alert is about.
  final NotificationKind kind;

  /// The localisation key a screen will render.
  final String subject;

  /// What that key needs filling in with.
  final Map<String, String> arguments;
}
