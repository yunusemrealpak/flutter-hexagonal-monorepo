import 'push_message_kind.dart';

/// A push, after the provider's envelope has been stripped off.
///
/// Not a domain type: `notifications` will declare what it wants to show, and
/// `shipments` will decide what a `shipmentAssigned` push means for its state
/// machine. This is the shape those decisions are made from.
final class PushMessage {
  /// Records a [kind] of push, sent at [sentAt].
  const PushMessage({
    required this.id,
    required this.kind,
    required this.data,
    required this.sentAt,
    this.title,
    this.body,
  });

  /// The provider's message identifier, or an empty string when it sent none.
  ///
  /// Push delivery is at-least-once: the same message can arrive twice, and
  /// this is what lets a caller notice.
  final String id;

  /// What the push is about.
  final PushMessageKind kind;

  /// The payload as it arrived, with every value stringified.
  ///
  /// Kept whole even after [kind] has been read from it, so that a message of
  /// an unrecognised kind still carries everything a later app version would
  /// have needed.
  final Map<String, String> data;

  /// When the provider says it sent the message, in UTC.
  ///
  /// Falls back to the moment of receipt when the provider did not say. Push
  /// can be delivered long after it was sent — a phone that was off, a network
  /// that was down — so the difference is worth keeping.
  final DateTime sentAt;

  /// The notification title, when the push carried one.
  final String? title;

  /// The notification body, when the push carried one.
  final String? body;

  @override
  String toString() => 'PushMessage(${kind.name}, $id)';
}
