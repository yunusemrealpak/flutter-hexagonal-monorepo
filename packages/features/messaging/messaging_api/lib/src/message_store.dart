import 'package:core_kernel/core_kernel.dart';

import 'message.dart';
import 'messaging_failure.dart';

/// Where a device keeps the threads it knows about.
///
/// The offline queue is this port and not a second one. A message is written
/// here first and sent afterwards; what is queued is simply what is stored and
/// not yet sent. A separate outbox would be a second list to keep in step with
/// the thread a courier is looking at, and the two would disagree the first
/// time a send failed halfway.
abstract interface class MessageStore {
  /// Every message in [threadId], oldest first.
  ///
  /// An empty list is a successful read: most threads have never been opened.
  Future<Result<List<Message>, MessagingFailure>> thread(String threadId);

  /// Stores [message], replacing any with the same identifier.
  ///
  /// Replacement rather than refusal, because this is how a message moves from
  /// queued to sent: the same identifier, one more instant on it.
  Future<Result<void, MessagingFailure>> put(Message message);

  /// Every message this device has written and not yet sent, oldest first.
  ///
  /// Oldest first is part of the contract, not a convenience. A thread resent
  /// in the wrong order arrives at the operation as an argument that reads
  /// backwards.
  Future<Result<List<Message>, MessagingFailure>> queued();
}
