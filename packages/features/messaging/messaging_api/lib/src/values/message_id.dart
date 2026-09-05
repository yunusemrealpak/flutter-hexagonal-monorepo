import 'package:core_kernel/core_kernel.dart';

import '../failures/messaging_failure.dart';

/// Identifies one message.
///
/// Minted on the device that wrote the message, by `IdGenerator`, **before**
/// it is sent. That is what makes the offline queue safe: the identifier
/// exists while the message is still waiting, so a resend after a timeout is
/// recognisably the same message rather than a second one. A server-assigned
/// identifier would be unavailable at exactly the moment this feature needs
/// one.
final class MessageId extends ValueObject<String> {
  const MessageId._(super.value);

  /// Reads a message identifier from [raw].
  static Result<MessageId, MessagingFailure> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const Failed(
        MalformedMessage(field: 'id', reason: 'it is empty'),
      );
    }
    return Success(MessageId._(trimmed));
  }
}
