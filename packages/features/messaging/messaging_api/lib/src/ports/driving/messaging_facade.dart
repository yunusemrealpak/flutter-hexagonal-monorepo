import 'package:core_kernel/core_kernel.dart';
import 'package:identity_api/identity_api.dart';

import '../../entities/message.dart';
import '../../failures/messaging_failure.dart';
import '../../values/thread_id.dart';

/// What the rest of the product may ask messaging to do.
///
/// A driving port, speaking in `ActorId`. The driven ports beside it speak in
/// `String` and in whole `Message`s.
abstract interface class MessagingFacade {
  /// Everything in [thread], oldest first.
  Future<Result<List<Message>, MessagingFailure>> read(ThreadId thread);

  /// Writes a message and tries to send it.
  ///
  /// **Succeeds when the message is stored, not when it is sent.** A courier
  /// in a tunnel has written the message; telling them it failed would make
  /// them write it again, and the operation would get it twice. The message
  /// comes back queued, and the screen shows that.
  Future<Result<Message, MessagingFailure>> send({
    required ThreadId thread,
    required ActorId author,
    required String body,
  });

  /// Records that [reader] has seen everything in [thread].
  Future<Result<List<Message>, MessagingFailure>> markRead({
    required ThreadId thread,
    required ActorId reader,
  });

  /// Emits a thread whenever anything in it changes.
  ///
  /// Broadcast and not replayed: a subscriber that needs the current state
  /// asks [read] for it.
  Stream<ThreadId> changes();
}
